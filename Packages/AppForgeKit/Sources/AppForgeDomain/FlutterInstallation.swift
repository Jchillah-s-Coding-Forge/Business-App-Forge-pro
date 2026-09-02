import Foundation

public enum FlutterSDKArchitecture: String, Codable, Equatable, Sendable {
    case arm64
    case x64
}

public struct FlutterReleaseArtifact: Codable, Equatable, Sendable {
    public let version: String
    public let architecture: FlutterSDKArchitecture
    public let archivePath: String
    public let sha256: String

    public init(
        version: String,
        architecture: FlutterSDKArchitecture,
        archivePath: String,
        sha256: String
    ) {
        self.version = version
        self.architecture = architecture
        self.archivePath = archivePath
        self.sha256 = sha256
    }
}

public enum FlutterInstallationPhase: String, Codable, Equatable, Sendable {
    case resolvingRelease
    case downloading
    case verifying
    case extracting
    case validating
    case completed
}

public struct FlutterInstallationResult: Codable, Equatable, Sendable {
    public let sdkPath: String
    public let version: String

    public init(sdkPath: String, version: String) {
        self.sdkPath = sdkPath
        self.version = version
    }
}
