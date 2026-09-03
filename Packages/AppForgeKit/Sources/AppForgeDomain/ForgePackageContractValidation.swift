import Foundation

public enum ForgePackageContractValidationIssue: Equatable, Sendable {
    case invalidPackageID(String)
    case invalidDependencyID(String)
    case invalidCapabilityID(String)
    case invalidVersionConstraint(packageID: String)
    case duplicateDependency(String)
    case selfDependency(String)
    case duplicateRequiredCapability(String)
    case duplicateProvidedCapability(String)
    case duplicateConflict(String)
    case selfConflict(String)
    case invalidBundledSourceMetadata
    case missingGitHubRepository
    case invalidGitHubRepository(String)
    case missingGitHubReference
    case invalidSHA256(String)
}

public struct ForgePackageContractValidationReport: Equatable, Sendable {
    public let issues: [ForgePackageContractValidationIssue]

    public var isValid: Bool { issues.isEmpty }

    public init(issues: [ForgePackageContractValidationIssue]) {
        self.issues = issues
    }
}

public struct ForgePackageContractValidator: Sendable {
    public init() {}

    public func report(_ contract: ForgePackageContract) -> ForgePackageContractValidationReport {
        ForgePackageContractValidationReport(issues: validate(contract))
    }

    public func validate(_ contract: ForgePackageContract) -> [ForgePackageContractValidationIssue] {
        var issues: [ForgePackageContractValidationIssue] = []

        if !Self.isValidNamespacedIdentifier(contract.id.rawValue) {
            issues.append(.invalidPackageID(contract.id.rawValue))
        }

        issues += validateDependencies(contract)
        issues += validateCapabilities(contract)
        issues += validateConflicts(contract)
        issues += validateSource(contract.source)
        return issues
    }

    private func validateDependencies(_ contract: ForgePackageContract) -> [ForgePackageContractValidationIssue] {
        var issues: [ForgePackageContractValidationIssue] = []
        var seen = Set<ForgePackageID>()

        for dependency in contract.dependencies {
            if !Self.isValidNamespacedIdentifier(dependency.packageID.rawValue) {
                issues.append(.invalidDependencyID(dependency.packageID.rawValue))
            }
            if !dependency.versionConstraint.isSatisfiable {
                issues.append(.invalidVersionConstraint(packageID: dependency.packageID.rawValue))
            }
            if dependency.packageID == contract.id {
                issues.append(.selfDependency(contract.id.rawValue))
            }
            if !seen.insert(dependency.packageID).inserted {
                issues.append(.duplicateDependency(dependency.packageID.rawValue))
            }
        }

        return issues
    }

    private func validateCapabilities(_ contract: ForgePackageContract) -> [ForgePackageContractValidationIssue] {
        var issues: [ForgePackageContractValidationIssue] = []
        var required = Set<ForgeCapabilityID>()
        var provided = Set<ForgeCapabilityID>()

        for capability in contract.requiredCapabilities {
            if !Self.isValidNamespacedIdentifier(capability.rawValue) {
                issues.append(.invalidCapabilityID(capability.rawValue))
            }
            if !required.insert(capability).inserted {
                issues.append(.duplicateRequiredCapability(capability.rawValue))
            }
        }

        for capability in contract.providedCapabilities {
            if !Self.isValidNamespacedIdentifier(capability.rawValue) {
                issues.append(.invalidCapabilityID(capability.rawValue))
            }
            if !provided.insert(capability).inserted {
                issues.append(.duplicateProvidedCapability(capability.rawValue))
            }
        }

        return issues
    }

    private func validateConflicts(_ contract: ForgePackageContract) -> [ForgePackageContractValidationIssue] {
        var issues: [ForgePackageContractValidationIssue] = []
        var seen = Set<ForgePackageID>()

        for conflict in contract.conflicts {
            if !Self.isValidNamespacedIdentifier(conflict.rawValue) {
                issues.append(.invalidPackageID(conflict.rawValue))
            }
            if conflict == contract.id {
                issues.append(.selfConflict(contract.id.rawValue))
            }
            if !seen.insert(conflict).inserted {
                issues.append(.duplicateConflict(conflict.rawValue))
            }
        }
        return issues
    }

    private func validateSource(_ source: ForgePackageSource) -> [ForgePackageContractValidationIssue] {
        switch source.kind {
        case .bundled:
            guard source.repository == nil, source.reference == nil, source.sha256 == nil else {
                return [.invalidBundledSourceMetadata]
            }
            return []
        case .github:
            var issues: [ForgePackageContractValidationIssue] = []
            guard let repository = source.repository, !repository.isEmpty else {
                return [.missingGitHubRepository]
            }
            if !Self.isValidGitHubRepository(repository) {
                issues.append(.invalidGitHubRepository(repository))
            }
            if source.reference?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
                issues.append(.missingGitHubReference)
            }
            guard let sha256 = source.sha256 else {
                issues.append(.invalidSHA256(""))
                return issues
            }
            if !Self.isValidSHA256(sha256) {
                issues.append(.invalidSHA256(sha256))
            }
            return issues
        }
    }

    private static func isValidNamespacedIdentifier(_ value: String) -> Bool {
        let segments = value.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count >= 2 else { return false }

        return segments.allSatisfy { segment in
            guard let first = segment.first, first.isASCII, first.isLowercase else { return false }
            return segment.allSatisfy { character in
                character.isASCII && (character.isLowercase || character.isNumber || character == "_")
            }
        }
    }

    private static func isValidGitHubRepository(_ value: String) -> Bool {
        let parts = value.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return false }
        return parts.allSatisfy { part in
            !part.isEmpty && part.allSatisfy { character in
                character.isASCII
                    && (character.isLetter
                        || character.isNumber
                        || character == "-"
                        || character == "_"
                        || character == ".")
            }
        }
    }

    private static func isValidSHA256(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy { character in
            character.isNumber || ("a" ... "f").contains(character)
        }
    }
}
