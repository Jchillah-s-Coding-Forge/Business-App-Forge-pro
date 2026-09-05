import Foundation

public enum DevelopmentEnvironmentMode: String, CaseIterable, Codable, Sendable {
    case appForgeManaged
    case existingToolchain
    case nixReproducible
}

public enum NixEnvironmentSystem: String, CaseIterable, Codable, Comparable, Sendable {
    case aarch64Darwin = "aarch64-darwin"
    case x86_64Darwin = "x86_64-darwin"

    public static func < (
        lhs: NixEnvironmentSystem,
        rhs: NixEnvironmentSystem
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum NixEnvironmentPackage: String, CaseIterable, Codable, Comparable, Sendable {
    case flutter
    case git
    case jdk17

    public static func < (
        lhs: NixEnvironmentPackage,
        rhs: NixEnvironmentPackage
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct NixEnvironmentPlan: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultNixpkgsInput = "github:NixOS/nixpkgs/nixos-unstable"

    public let schemaVersion: Int
    public let nixpkgsInput: String
    public let systems: [NixEnvironmentSystem]
    public let packages: [NixEnvironmentPackage]
    public let unmanagedRequirements: [ToolIdentifier]

    public init(
        schemaVersion: Int = NixEnvironmentPlan.currentSchemaVersion,
        nixpkgsInput: String = NixEnvironmentPlan.defaultNixpkgsInput,
        systems: [NixEnvironmentSystem],
        packages: [NixEnvironmentPackage],
        unmanagedRequirements: [ToolIdentifier]
    ) {
        self.schemaVersion = schemaVersion
        self.nixpkgsInput = nixpkgsInput
        self.systems = systems.sorted()
        self.packages = packages.sorted()
        self.unmanagedRequirements = unmanagedRequirements.sorted {
            $0.rawValue < $1.rawValue
        }
    }
}

public struct NixEnvironmentReceipt: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultFileName = "appforge.nix-environment.json"

    public let schemaVersion: Int
    public let nixVersion: String
    public let nixpkgsLockedRevision: String
    public let flakeLockSHA256: String
    public let systems: [NixEnvironmentSystem]
    public let packages: [NixEnvironmentPackage]
    public let validationTool: String
    public let validationVersion: String

    public init(
        schemaVersion: Int = NixEnvironmentReceipt.currentSchemaVersion,
        nixVersion: String,
        nixpkgsLockedRevision: String,
        flakeLockSHA256: String,
        systems: [NixEnvironmentSystem],
        packages: [NixEnvironmentPackage],
        validationTool: String,
        validationVersion: String
    ) {
        self.schemaVersion = schemaVersion
        self.nixVersion = nixVersion
        self.nixpkgsLockedRevision = nixpkgsLockedRevision
        self.flakeLockSHA256 = flakeLockSHA256
        self.systems = systems.sorted()
        self.packages = packages.sorted()
        self.validationTool = validationTool
        self.validationVersion = validationVersion
    }
}

public struct NixEnvironmentReceiptCodec: Sendable {
    public init() {}

    public func encode(_ receipt: NixEnvironmentReceipt) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(receipt)
    }

    public func decode(_ data: Data) throws -> NixEnvironmentReceipt {
        try JSONDecoder().decode(NixEnvironmentReceipt.self, from: data)
    }
}

public enum NixEnvironmentError: Error, Equatable, Sendable {
    case unsupportedFramework(OutputFramework)
    case incompatibleNixVersion(actual: String, minimum: String)
    case invalidNixExecutable
    case invalidFlakeLock
    case missingLockedNixpkgsRevision
    case targetAlreadyExists
    case commandTimedOut(String)
    case commandFailed(command: String, exitCode: Int32, output: String)
}
