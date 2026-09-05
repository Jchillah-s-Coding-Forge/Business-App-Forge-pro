import AppForgeDomain
import Foundation

public struct PackageResolver: Sendable {
    private let contractValidator: ForgePackageContractValidator

    public init(contractValidator: ForgePackageContractValidator = ForgePackageContractValidator()) {
        self.contractValidator = contractValidator
    }

    public func resolve(
        requests: [ForgePackageRequirement],
        specification: ProjectSpecification,
        registry: some PackageRegistry
    ) throws -> ResolvedProductGraph {
        let initialState = ResolutionState(
            selected: [:],
            constraints: [:],
            pending: requests
        )
        let selected = try resolveState(
            initialState,
            specification: specification,
            registry: registry
        )
        return try makeGraph(from: selected)
    }

    private func resolveState(
        _ incomingState: ResolutionState,
        specification: ProjectSpecification,
        registry: some PackageRegistry
    ) throws -> [ForgePackageID: ForgePackageContract] {
        guard !incomingState.pending.isEmpty else {
            try validateConflicts(incomingState.selected)
            try validateCapabilities(incomingState.selected)
            _ = try topologicallySortedContracts(incomingState.selected)
            return incomingState.selected
        }

        var state = incomingState
        state.pending.sort(by: Self.requirementSort)
        let requirement = state.pending.removeFirst()
        state.constraints[requirement.packageID, default: []].append(requirement.versionConstraint)
        state.constraints[requirement.packageID]?.sort { $0.description < $1.description }

        let constraints = state.constraints[requirement.packageID] ?? []
        if let alreadySelected = state.selected[requirement.packageID] {
            guard constraints.allSatisfy({ $0.accepts(alreadySelected.version) }) else {
                throw PackageResolutionError.noCompatibleVersion(
                    packageID: requirement.packageID,
                    constraints: constraints
                )
            }
            return try resolveState(state, specification: specification, registry: registry)
        }

        let candidates = try validatedCandidates(
            for: requirement.packageID,
            constraints: constraints,
            specification: specification,
            registry: registry
        )

        var lastResolutionError: PackageResolutionError?
        for candidate in candidates {
            do {
                try validateImmediateConflicts(candidate, selected: state.selected)
                var next = state
                next.selected[candidate.id] = candidate
                next.pending.append(contentsOf: candidate.dependencies)
                return try resolveState(next, specification: specification, registry: registry)
            } catch let error as PackageResolutionError {
                lastResolutionError = error
            }
        }

        throw lastResolutionError ?? PackageResolutionError.noCompatibleVersion(
            packageID: requirement.packageID,
            constraints: constraints
        )
    }

    private func validatedCandidates(
        for packageID: ForgePackageID,
        constraints: [ForgeVersionConstraint],
        specification: ProjectSpecification,
        registry: some PackageRegistry
    ) throws -> [ForgePackageContract] {
        let registered = registry.contracts(for: packageID)
        guard !registered.isEmpty else {
            throw PackageResolutionError.packageNotFound(packageID)
        }

        var seenVersions = Set<ForgeSemanticVersion>()
        for contract in registered {
            let issues = contractValidator.validate(contract)
            guard issues.isEmpty else {
                throw PackageResolutionError.invalidContract(packageID: contract.id, issues: issues)
            }
            guard seenVersions.insert(contract.version).inserted else {
                throw PackageResolutionError.duplicatePackageVersion(
                    packageID: contract.id,
                    version: contract.version
                )
            }
        }

        let frameworkCompatible = registered.filter { contract in
            contract.supportedFrameworks.isEmpty || contract.supportedFrameworks.contains(specification.framework)
        }
        guard !frameworkCompatible.isEmpty else {
            throw PackageResolutionError.incompatibleFramework(
                packageID: packageID,
                framework: specification.framework
            )
        }

        let backendCompatible = frameworkCompatible.filter { contract in
            contract.supportedBackends.isEmpty || contract.supportedBackends.contains(specification.backend)
        }
        guard !backendCompatible.isEmpty else {
            throw PackageResolutionError.incompatibleBackend(
                packageID: packageID,
                backend: specification.backend
            )
        }

        let candidates = backendCompatible
            .filter { contract in
                constraints.allSatisfy { $0.accepts(contract.version) }
            }
            .sorted(by: Self.contractSort)

        guard !candidates.isEmpty else {
            throw PackageResolutionError.noCompatibleVersion(
                packageID: packageID,
                constraints: constraints
            )
        }
        return candidates
    }

    private func validateImmediateConflicts(
        _ candidate: ForgePackageContract,
        selected: [ForgePackageID: ForgePackageContract]
    ) throws {
        for other in selected.values.sorted(by: { $0.id < $1.id }) {
            if candidate.conflicts.contains(other.id) || other.conflicts.contains(candidate.id) {
                let ordered = [candidate.id, other.id].sorted()
                throw PackageResolutionError.packageConflict(ordered[0], ordered[1])
            }
        }
    }

    private func validateConflicts(_ selected: [ForgePackageID: ForgePackageContract]) throws {
        let contracts = selected.values.sorted(by: { $0.id < $1.id })
        for contract in contracts {
            for conflict in contract.conflicts.sorted() where selected[conflict] != nil {
                let ordered = [contract.id, conflict].sorted()
                throw PackageResolutionError.packageConflict(ordered[0], ordered[1])
            }
        }
    }

    private func validateCapabilities(_ selected: [ForgePackageID: ForgePackageContract]) throws {
        let provided = Set(selected.values.flatMap(\.providedCapabilities))
        let required = Set(selected.values.flatMap(\.requiredCapabilities))
        let missing = required.subtracting(provided).sorted()
        guard missing.isEmpty else {
            throw PackageResolutionError.missingCapabilities(missing)
        }
    }

    private func makeGraph(
        from selected: [ForgePackageID: ForgePackageContract]
    ) throws -> ResolvedProductGraph {
        let contracts = try topologicallySortedContracts(selected)
        let capabilities = Set(contracts.flatMap(\.providedCapabilities)).sorted()
        return ResolvedProductGraph(
            packages: contracts.map(ResolvedPackage.init(contract:)),
            capabilities: capabilities
        )
    }

    private func topologicallySortedContracts(
        _ selected: [ForgePackageID: ForgePackageContract]
    ) throws -> [ForgePackageContract] {
        var permanent = Set<ForgePackageID>()
        var temporary = Set<ForgePackageID>()
        var path: [ForgePackageID] = []
        var result: [ForgePackageContract] = []

        func visit(_ packageID: ForgePackageID) throws {
            if permanent.contains(packageID) {
                return
            }
            if temporary.contains(packageID) {
                let cycleStart = path.firstIndex(of: packageID) ?? path.startIndex
                let cycle = Array(path[cycleStart...]) + [packageID]
                throw PackageResolutionError.dependencyCycle(cycle)
            }
            guard let contract = selected[packageID] else { return }

            temporary.insert(packageID)
            path.append(packageID)
            for dependency in contract.dependencies.sorted(by: Self.requirementSort) {
                try visit(dependency.packageID)
            }
            _ = path.popLast()
            temporary.remove(packageID)
            permanent.insert(packageID)
            result.append(contract)
        }

        for packageID in selected.keys.sorted() {
            try visit(packageID)
        }
        return result
    }

    static func contractSort(_ lhs: ForgePackageContract, _ rhs: ForgePackageContract) -> Bool {
        if lhs.version < rhs.version {
            return false
        }
        if rhs.version < lhs.version {
            return true
        }
        if lhs.version.description != rhs.version.description {
            return lhs.version.description < rhs.version.description
        }
        return lhs.id < rhs.id
    }

    private static func requirementSort(_ lhs: ForgePackageRequirement, _ rhs: ForgePackageRequirement) -> Bool {
        if lhs.packageID != rhs.packageID {
            return lhs.packageID < rhs.packageID
        }
        return lhs.versionConstraint.description < rhs.versionConstraint.description
    }
}

private struct ResolutionState {
    var selected: [ForgePackageID: ForgePackageContract]
    var constraints: [ForgePackageID: [ForgeVersionConstraint]]
    var pending: [ForgePackageRequirement]
}
