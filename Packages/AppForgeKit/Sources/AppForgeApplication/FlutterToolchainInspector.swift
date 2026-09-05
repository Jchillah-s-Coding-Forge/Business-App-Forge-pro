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
        let paths = try validatedSDKPaths(sdkRootPath)
        let result = try runVersionCommand(paths)
        let identity = try parseIdentity(result.output)
        try validateMinimumVersion(identity.flutterVersion)

        return FlutterToolchainInspection(
            sdkRootPath: paths.root.path,
            flutterExecutablePath: paths.executable.path,
            identity: identity
        )
    }

    private func validatedSDKPaths(
        _ sdkRootPath: String
    ) throws -> FlutterSDKPaths {
        let rootURL = URL(
            fileURLWithPath: NSString(string: sdkRootPath).expandingTildeInPath,
            isDirectory: true
        )
        .standardizedFileURL
        .resolvingSymlinksInPath()

        var isDirectory: ObjCBool = false
        let rootExists = FileManager.default.fileExists(
            atPath: rootURL.path,
            isDirectory: &isDirectory
        )
        guard !sdkRootPath.isEmpty, rootExists, isDirectory.boolValue else {
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

        return FlutterSDKPaths(
            root: rootURL,
            executable: executableURL
        )
    }

    private func runVersionCommand(
        _ paths: FlutterSDKPaths
    ) throws -> ToolchainCommandResult {
        let result = try runner.run(
            ToolchainCommandRequest(
                executablePath: paths.executable.path,
                arguments: ["--no-version-check", "--version", "--machine"],
                workingDirectoryPath: paths.root.path,
                environment: FlutterToolchainProcessEnvironment.make(
                    sdkRootPath: paths.root.path
                ),
                timeoutSeconds: 30
            )
        )

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
        return result
    }

    private func parseIdentity(
        _ output: String
    ) throws -> FlutterToolchainIdentity {
        let dictionary = try machineVersionDictionary(output)
        guard let version = stringValue(
            in: dictionary,
            keys: ["flutterVersion", "frameworkVersion"]
        ) else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard let channel = dictionary["channel"] as? String else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard let frameworkRevision = dictionary["frameworkRevision"] as? String else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard let engineRevision = dictionary["engineRevision"] as? String else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard let dartSDKVersion = dictionary["dartSdkVersion"] as? String else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        let metadataIsValid = !version.isEmpty
            && !channel.isEmpty
            && frameworkRevision.isGitRevision
            && engineRevision.isGitRevision
            && !dartSDKVersion.isEmpty
        guard metadataIsValid else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        return FlutterToolchainIdentity(
            flutterVersion: version,
            channel: channel,
            frameworkRevision: frameworkRevision,
            engineRevision: engineRevision,
            dartSDKVersion: dartSDKVersion
        )
    }

    private func machineVersionDictionary(
        _ output: String
    ) throws -> [String: Any] {
        guard let firstBrace = output.firstIndex(of: "{"),
              let lastBrace = output.lastIndex(of: "}"),
              firstBrace <= lastBrace
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        let json = String(output[firstBrace ... lastBrace])
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        return dictionary
    }

    private func stringValue(
        in dictionary: [String: Any],
        keys: [String]
    ) -> String? {
        keys.lazy.compactMap { dictionary[$0] as? String }.first
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

private extension String {
    var isGitRevision: Bool {
        range(
            of: "^[0-9a-fA-F]{7,64}$",
            options: .regularExpression
        ) != nil
    }
}

private struct FlutterSDKPaths {
    let root: URL
    let executable: URL
}
