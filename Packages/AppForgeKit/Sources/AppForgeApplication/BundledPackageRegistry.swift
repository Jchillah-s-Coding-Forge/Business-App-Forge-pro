import AppForgeDomain

public enum BundledPackageRegistryError: Error, Equatable, Sendable {
    case invalidBundledVersion(String)
}

public struct BundledPackageRegistry: PackageRegistry, Sendable {
    public static let foundationCoreID = ForgePackageID(
        "foundation.core"
    )

    private let registry: InMemoryPackageRegistry

    public init() throws {
        registry = try InMemoryPackageRegistry(
            contracts: Self.contracts()
        )
    }

    public func contracts(
        for packageID: ForgePackageID
    ) -> [ForgePackageContract] {
        registry.contracts(for: packageID)
    }

    public static var defaultRootRequirements: [ForgePackageRequirement] {
        [
            ForgePackageRequirement(
                packageID: foundationCoreID
            )
        ]
    }

    private static func contracts() throws -> [ForgePackageContract] {
        [
            try foundationCore()
        ]
    }

    private static func foundationCore() throws -> ForgePackageContract {
        let versionText = "1.0.0"
        guard let version = ForgeSemanticVersion(
            versionText
        ) else {
            throw BundledPackageRegistryError
                .invalidBundledVersion(versionText)
        }

        return ForgePackageContract(
            id: foundationCoreID,
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            maturity: .stable,
            source: .bundled
        )
    }
}
