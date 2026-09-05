import Foundation

public enum FlutterMaterializationStep: String, Codable, Equatable, Sendable {
    case inspectToolchain
    case create
    case pubGet
    case analyze
    case test
}

public struct FlutterToolchainIdentity: Codable, Equatable, Sendable {
    public let flutterVersion: String
    public let channel: String
    public let frameworkRevision: String
    public let engineRevision: String
    public let dartSDKVersion: String

    public init(
        flutterVersion: String,
        channel: String,
        frameworkRevision: String,
        engineRevision: String,
        dartSDKVersion: String
    ) {
        self.flutterVersion = flutterVersion
        self.channel = channel
        self.frameworkRevision = frameworkRevision
        self.engineRevision = engineRevision
        self.dartSDKVersion = dartSDKVersion
    }
}

public struct FlutterToolchainReceipt: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1
    public static let defaultFileName = "appforge.toolchain.json"

    public let schemaVersion: Int
    public let flutter: FlutterToolchainIdentity
    public let projectPackageName: String
    public let organizationIdentifier: String
    public let targetPlatforms: [TargetPlatform]
    public let pubspecLockSHA256: String
    public let validatedSteps: [FlutterMaterializationStep]

    public init(
        schemaVersion: Int = FlutterToolchainReceipt.currentSchemaVersion,
        flutter: FlutterToolchainIdentity,
        projectPackageName: String,
        organizationIdentifier: String,
        targetPlatforms: [TargetPlatform],
        pubspecLockSHA256: String,
        validatedSteps: [FlutterMaterializationStep]
    ) {
        self.schemaVersion = schemaVersion
        self.flutter = flutter
        self.projectPackageName = projectPackageName
        self.organizationIdentifier = organizationIdentifier
        self.targetPlatforms = targetPlatforms
        self.pubspecLockSHA256 = pubspecLockSHA256
        self.validatedSteps = validatedSteps
    }
}

public struct FlutterToolchainReceiptCodec: Sendable {
    public init() {}

    public func encode(_ receipt: FlutterToolchainReceipt) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(receipt)
    }

    public func decode(_ data: Data) throws -> FlutterToolchainReceipt {
        try JSONDecoder().decode(FlutterToolchainReceipt.self, from: data)
    }
}

public enum FlutterMaterializationError: Error, Equatable, Sendable {
    case invalidSpecification([ProjectSpecificationValidationIssue])
    case invalidFlutterSDKPath
    case invalidFlutterToolchainMetadata
    case incompatibleFlutterVersion(actual: String, minimum: String)
    case targetAlreadyExists
    case generationPlanMismatch
    case missingPubspecLock
    case unsupportedTargetPlatform(TargetPlatform)
    case commandTimedOut(FlutterMaterializationStep)
    case commandFailed(
        step: FlutterMaterializationStep,
        exitCode: Int32,
        output: String
    )
}
