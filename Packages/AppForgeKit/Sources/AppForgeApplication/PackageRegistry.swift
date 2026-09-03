import AppForgeDomain
import Foundation

public protocol PackageRegistry: Sendable {
    func contracts(for packageID: ForgePackageID) -> [ForgePackageContract]
}

public enum PackageResolutionError: Error, Equatable, Sendable {
    case invalidProjectSpecification([ProjectSpecificationValidationIssue])
    case invalidContract(packageID: ForgePackageID, issues: [ForgePackageContractValidationIssue])
    case duplicatePackageVersion(packageID: ForgePackageID, version: ForgeSemanticVersion)
    case packageNotFound(ForgePackageID)
    case incompatibleFramework(packageID: ForgePackageID, framework: OutputFramework)
    case incompatibleBackend(packageID: ForgePackageID, backend: BackendProvider)
    case noCompatibleVersion(packageID: ForgePackageID, constraints: [ForgeVersionConstraint])
    case packageConflict(ForgePackageID, ForgePackageID)
    case dependencyCycle([ForgePackageID])
    case missingCapabilities([ForgeCapabilityID])
}

public struct InMemoryPackageRegistry: PackageRegistry, Sendable {
    private let contractsByID: [ForgePackageID: [ForgePackageContract]]

    public init(
        contracts: [ForgePackageContract],
        validator: ForgePackageContractValidator = ForgePackageContractValidator()
    ) throws {
        var grouped: [ForgePackageID: [ForgePackageContract]] = [:]
        var seenVersions: [ForgePackageID: Set<ForgeSemanticVersion>] = [:]

        for contract in contracts {
            let issues = validator.validate(contract)
            guard issues.isEmpty else {
                throw PackageResolutionError.invalidContract(packageID: contract.id, issues: issues)
            }

            if !(seenVersions[contract.id, default: []].insert(contract.version).inserted) {
                throw PackageResolutionError.duplicatePackageVersion(
                    packageID: contract.id,
                    version: contract.version
                )
            }
            grouped[contract.id, default: []].append(contract)
        }

        contractsByID = grouped.mapValues { contracts in
            contracts.sorted(by: PackageResolver.contractSort)
        }
    }

    public func contracts(for packageID: ForgePackageID) -> [ForgePackageContract] {
        contractsByID[packageID] ?? []
    }
}
