import Foundation

public enum ForgePackageKind: String, CaseIterable, Codable, Sendable {
    case foundation
    case domain
    case feature
    case integration
    case policy
    case workflow
    case renderer
    case template
}

public enum ForgePackageMaturity: String, CaseIterable, Codable, Comparable, Sendable {
    case experimental
    case beta
    case stable
    case golden

    public static func < (lhs: ForgePackageMaturity, rhs: ForgePackageMaturity) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .experimental: 0
        case .beta: 1
        case .stable: 2
        case .golden: 3
        }
    }
}

public enum ForgePackageSourceKind: String, Codable, Sendable {
    case bundled
    case github
}

public struct ForgePackageSource: Codable, Equatable, Sendable {
    public let kind: ForgePackageSourceKind
    public let repository: String?
    public let reference: String?
    public let sha256: String?

    public init(
        kind: ForgePackageSourceKind,
        repository: String? = nil,
        reference: String? = nil,
        sha256: String? = nil
    ) {
        self.kind = kind
        self.repository = repository
        self.reference = reference
        self.sha256 = sha256
    }

    public static let bundled = ForgePackageSource(kind: .bundled)

    public static func github(repository: String, reference: String, sha256: String) -> ForgePackageSource {
        ForgePackageSource(
            kind: .github,
            repository: repository,
            reference: reference,
            sha256: sha256
        )
    }
}

public struct ForgePackageRequirement: Codable, Equatable, Sendable {
    public let packageID: ForgePackageID
    public let versionConstraint: ForgeVersionConstraint

    public init(
        packageID: ForgePackageID,
        versionConstraint: ForgeVersionConstraint = .any
    ) {
        self.packageID = packageID
        self.versionConstraint = versionConstraint
    }
}

public struct ForgePackageContract: Codable, Equatable, Sendable {
    public let id: ForgePackageID
    public let version: ForgeSemanticVersion
    public let kind: ForgePackageKind
    public let dependencies: [ForgePackageRequirement]
    public let requiredCapabilities: [ForgeCapabilityID]
    public let providedCapabilities: [ForgeCapabilityID]
    public let conflicts: [ForgePackageID]
    public let supportedFrameworks: [OutputFramework]
    public let supportedBackends: [BackendProvider]
    public let maturity: ForgePackageMaturity
    public let source: ForgePackageSource

    public init(
        id: ForgePackageID,
        version: ForgeSemanticVersion,
        kind: ForgePackageKind,
        dependencies: [ForgePackageRequirement] = [],
        requiredCapabilities: [ForgeCapabilityID] = [],
        providedCapabilities: [ForgeCapabilityID] = [],
        conflicts: [ForgePackageID] = [],
        supportedFrameworks: [OutputFramework] = [],
        supportedBackends: [BackendProvider] = [],
        maturity: ForgePackageMaturity = .experimental,
        source: ForgePackageSource = .bundled
    ) {
        self.id = id
        self.version = version
        self.kind = kind
        self.dependencies = dependencies
        self.requiredCapabilities = requiredCapabilities
        self.providedCapabilities = providedCapabilities
        self.conflicts = conflicts
        self.supportedFrameworks = supportedFrameworks
        self.supportedBackends = supportedBackends
        self.maturity = maturity
        self.source = source
    }

    public func supports(_ specification: ProjectSpecification) -> Bool {
        let frameworkSupported = supportedFrameworks.isEmpty || supportedFrameworks.contains(specification.framework)
        let backendSupported = supportedBackends.isEmpty || supportedBackends.contains(specification.backend)
        return frameworkSupported && backendSupported
    }
}
