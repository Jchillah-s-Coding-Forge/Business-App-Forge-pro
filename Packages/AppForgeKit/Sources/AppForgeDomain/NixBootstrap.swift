import Foundation

public struct NixBootstrapReleasePolicy: Codable, Equatable, Sendable {
    public static let current = NixBootstrapReleasePolicy(
        version: "2.35.2",
        installerURLString: "https://releases.nixos.org/nix/nix-2.35.2/install",
        x86DarwinTarballSHA256: "d725518d89f3b0b8d4af702a9d38d519814014cbe125afb3ed0545c9d755f6a5",
        aarch64DarwinTarballSHA256: "1695c13aba5afa7c2ecd6dc4a9393f602e7bbc440ed45e81602c831546580ec3",
        maximumInstallerBytes: 524_288
    )

    public let version: String
    public let installerURLString: String
    public let x86DarwinTarballSHA256: String
    public let aarch64DarwinTarballSHA256: String
    public let maximumInstallerBytes: Int

    public init(
        version: String,
        installerURLString: String,
        x86DarwinTarballSHA256: String,
        aarch64DarwinTarballSHA256: String,
        maximumInstallerBytes: Int
    ) {
        self.version = version
        self.installerURLString = installerURLString
        self.x86DarwinTarballSHA256 = x86DarwinTarballSHA256
        self.aarch64DarwinTarballSHA256 = aarch64DarwinTarballSHA256
        self.maximumInstallerBytes = maximumInstallerBytes
    }
}

public struct NixBootstrapPreparedInstaller: Equatable, Sendable {
    public let version: String
    public let installerSHA256: String
    public let workspacePath: String
    public let installerPath: String
    public let commandPath: String

    public init(
        version: String,
        installerSHA256: String,
        workspacePath: String,
        installerPath: String,
        commandPath: String
    ) {
        self.version = version
        self.installerSHA256 = installerSHA256
        self.workspacePath = workspacePath
        self.installerPath = installerPath
        self.commandPath = commandPath
    }
}

public struct NixBootstrapConfirmation: Equatable, Sendable {
    public let approvedInstallerSHA256: String

    public init(approvedInstallerSHA256: String) {
        self.approvedInstallerSHA256 = approvedInstallerSHA256
    }
}

public enum NixBootstrapError: Error, Equatable, Sendable {
    case invalidReleaseURL
    case unexpectedResponseURL
    case invalidHTTPStatus(Int)
    case emptyInstaller
    case installerTooLarge(maximumBytes: Int)
    case invalidInstallerEncoding
    case installerStructureMismatch
    case installerDigestMismatch
    case confirmationMismatch
    case releasePolicyMismatch
    case invalidPreparedWorkspace
    case terminalLaunchFailed
}
