import AppForgeDomain
import Foundation

public struct FlutterToolchainInspection: Equatable, Sendable {
    public let sdkRootPath: String
    public let flutterExecutablePath: String
    public let identity: FlutterToolchainIdentity

    public init(
        sdkRootPath: String,
        flutterExecutablePath: String,
        identity: FlutterToolchainIdentity
    ) {
        self.sdkRootPath = sdkRootPath
        self.flutterExecutablePath = flutterExecutablePath
        self.identity = identity
    }
}

public protocol FlutterToolchainInspecting: Sendable {
    func inspect(sdkRootPath: String) throws -> FlutterToolchainInspection
}

public struct SystemFlutterToolchainInspector: FlutterToolchainInspecting {
    private let runner: any ToolchainCommandRunning

    public init(
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner()
    ) {
        self.runner = runner
    }

    public func inspect(
        sdkRootPath: String
    ) throws -> FlutterToolchainInspection {
        let rootURL = URL(
            fileURLWithPath: NSString(string: sdkRootPath).expandingTildeInPath,
            isDirectory: true
        )
        .standardizedFileURL
        .resolvingSymlinksInPath()

        var isDirectory: ObjCBool = false
        guard !sdkRootPath.isEmpty,
              FileManager.default.fileExists(
                  atPath: rootURL.path,
                  isDirectory: &isDirectory
              ),
              isDirectory.boolValue
        else {
            throw FlutterMaterializationError.invalidFlutterSDKPath
        }

        let executableURL = rootURL
            .appendingPathComponent("bin", isDirectory: true)
            .appendingPathComponent("flutter")
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let rootPrefix = rootURL.path + "/"

        guard executableURL.path.hasPrefix(rootPrefix),
              FileManager.default.isExecutableFile(atPath: executableURL.path)
        else {
            throw FlutterMaterializationError.invalidFlutterSDKPath
        }

        let request = ToolchainCommandRequest(
            executablePath: executableURL.path,
            arguments: ["--no-version-check", "--version", "--machine"],
            workingDirectoryPath: rootURL.path,
            environment: FlutterToolchainProcessEnvironment.make(
                sdkRootPath: rootURL.path
            ),
            timeoutSeconds: 30
        )
        let result = try runner.run(request)

        guard !result.timedOut else {
            throw FlutterMaterializationError.commandTimedOut(.inspectToolchain)
        }
        guard result.exitCode == 0 else {
            throw FlutterMaterializationError.commandFailed(
                step: .inspectToolchain,
                exitCode: result.exitCode,
                output: result.output
            )
        }

        let identity = try parseIdentity(result.output)
        try validateMinimumVersion(identity.flutterVersion)

        return FlutterToolchainInspection(
            sdkRootPath: rootURL.path,
            flutterExecutablePath: executableURL.path,
            identity: identity
        )
    }

    private func parseIdentity(
        _ output: String
    ) throws -> FlutterToolchainIdentity {
        guard let firstBrace = output.firstIndex(of: "{"),
              let lastBrace = output.lastIndex(of: "}"),
              firstBrace <= lastBrace
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        let json = String(output[firstBrace ... lastBrace])
        guard let data = json.data(using: .utf8),
              let machine = try? JSONDecoder().decode(
                  FlutterMachineVersion.self,
                  from: data
              ),
              !machine.version.isEmpty,
              !machine.channel.isEmpty,
              machine.frameworkRevision.isGitRevision,
              machine.engineRevision.isGitRevision,
              !machine.dartSDKVersion.isEmpty
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        return FlutterToolchainIdentity(
            flutterVersion: machine.version,
            channel: machine.channel,
            frameworkRevision: machine.frameworkRevision,
            engineRevision: machine.engineRevision,
            dartSDKVersion: machine.dartSDKVersion
        )
    }

    private func validateMinimumVersion(
        _ versionText: String
    ) throws {
        let minimum = SupportedToolVersions.flutter
        guard let version = SemanticVersion(parsing: versionText) else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard version >= minimum else {
            throw FlutterMaterializationError.incompatibleFlutterVersion(
                actual: versionText,
                minimum: minimum.description
            )
        }
    }
}

enum FlutterToolchainProcessEnvironment {
    static func make(
        sdkRootPath: String,
        inherited: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var environment = [
            "PATH": sdkRootPath + "/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "CI": "true",
            "TERM": "dumb",
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8",
            "PUB_ENVIRONMENT": "appforge"
        ]

        for key in ["HOME", "TMPDIR"] {
            if let value = inherited[key], !value.isEmpty {
                environment[key] = value
            }
        }

        return environment
    }
}

private struct FlutterMachineVersion: Decodable {
    let version: String
    let channel: String
    let frameworkRevision: String
    let engineRevision: String
    let dartSDKVersion: String

    private enum CodingKeys: String, CodingKey {
        case flutterVersion
        case frameworkVersion
        case channel
        case frameworkRevision
        case engineRevision
        case dartSDKVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(
            String.self,
            forKey: .flutterVersion
        )
            ?? container.decode(String.self, forKey: .frameworkVersion)
        channel = try container.decode(String.self, forKey: .channel)
        frameworkRevision = try container.decode(
            String.self,
            forKey: .frameworkRevision
        )
        engineRevision = try container.decode(
            String.self,
            forKey: .engineRevision
        )
        dartSDKVersion = try container.decode(
            String.self,
            forKey: .dartSDKVersion
        )
    }
}

private extension String {
    var isGitRevision: Bool {
        range(
            of: "^[0-9a-fA-F]{7,64}$",
            options: .regularExpression
        ) != nil
    }
}
