import Foundation

public struct ResolvedPackage: Codable, Equatable, Sendable {
    public let contract: ForgePackageContract

    public init(contract: ForgePackageContract) {
        self.contract = contract
    }
}

public struct ResolvedProductGraph: Codable, Equatable, Sendable {
    public let packages: [ResolvedPackage]
    public let capabilities: [ForgeCapabilityID]

    public init(packages: [ResolvedPackage], capabilities: [ForgeCapabilityID]) {
        self.packages = packages
        self.capabilities = capabilities
    }
}

public struct ForgeLockfileDependency: Codable, Equatable, Sendable {
    public let packageID: ForgePackageID
    public let version: ForgeSemanticVersion

    public init(packageID: ForgePackageID, version: ForgeSemanticVersion) {
        self.packageID = packageID
        self.version = version
    }
}

public struct ForgeLockfileEntry: Codable, Equatable, Sendable {
    public let packageID: ForgePackageID
    public let version: ForgeSemanticVersion
    public let kind: ForgePackageKind
    public let dependencies: [ForgeLockfileDependency]
    public let providedCapabilities: [ForgeCapabilityID]
    public let maturity: ForgePackageMaturity
    public let source: ForgePackageSource

    public init(
        packageID: ForgePackageID,
        version: ForgeSemanticVersion,
        kind: ForgePackageKind,
        dependencies: [ForgeLockfileDependency],
        providedCapabilities: [ForgeCapabilityID],
        maturity: ForgePackageMaturity,
        source: ForgePackageSource
    ) {
        self.packageID = packageID
        self.version = version
        self.kind = kind
        self.dependencies = dependencies
        self.providedCapabilities = providedCapabilities
        self.maturity = maturity
        self.source = source
    }
}

public struct ForgeLockfile: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultFileName = "forge.lock"

    public let schemaVersion: Int
    public let projectSchemaVersion: Int
    public let framework: OutputFramework
    public let backend: BackendProvider
    public let packages: [ForgeLockfileEntry]
    public let capabilities: [ForgeCapabilityID]

    public init(
        schemaVersion: Int = ForgeLockfile.currentSchemaVersion,
        projectSchemaVersion: Int,
        framework: OutputFramework,
        backend: BackendProvider,
        packages: [ForgeLockfileEntry],
        capabilities: [ForgeCapabilityID]
    ) {
        self.schemaVersion = schemaVersion
        self.projectSchemaVersion = projectSchemaVersion
        self.framework = framework
        self.backend = backend
        self.packages = packages
        self.capabilities = capabilities
    }
}

public struct ForgeLockfileCodec: Sendable {
    public init() {}

    public func encode(_ lockfile: ForgeLockfile) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(lockfile)
    }

    public func decode(_ data: Data) throws -> ForgeLockfile {
        try JSONDecoder().decode(ForgeLockfile.self, from: data)
    }
}
