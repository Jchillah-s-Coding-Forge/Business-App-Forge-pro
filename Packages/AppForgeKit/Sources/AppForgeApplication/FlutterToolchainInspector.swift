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
    func inspect(
        sdkRootPath: String
    ) throws -> FlutterToolchainInspection
}

public struct SystemFlutterToolchainInspector: FlutterToolchainInspecting {
    private let runner: any ToolchainCommandRunning
    private let parser: FlutterToolchainIdentityParser

    public init(
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner()
    ) {
        self.runner = runner
        parser = FlutterToolchainIdentityParser()
    }

    public func inspect(
        sdkRootPath: String
    ) throws -> FlutterToolchainInspection {
        let paths = try validatedSDKPaths(sdkRootPath)
        let result = try runVersionCommand(paths)
        let identity = try parser.parse(result.output)

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
            fileURLWithPath:
                NSString(string: sdkRootPath).expandingTildeInPath,
            isDirectory: true
        )
        .standardizedFileURL
        .resolvingSymlinksInPath()

        var isDirectory: ObjCBool = false
        let rootExists = FileManager.default.fileExists(
            atPath: rootURL.path,
            isDirectory: &isDirectory
        )
        guard !sdkRootPath.isEmpty,
              rootExists,
              isDirectory.boolValue
        else {
            throw FlutterMaterializationError.invalidFlutterSDKPath
        }

        let executableURL = rootURL
            .appendingPathComponent(
                "bin",
                isDirectory: true
            )
            .appendingPathComponent("flutter")
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let rootPrefix = rootURL.path + "/"

        guard executableURL.path.hasPrefix(rootPrefix),
              FileManager.default.isExecutableFile(
                  atPath: executableURL.path
              )
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
                arguments: [
                    "--no-version-check",
                    "--version",
                    "--machine"
                ],
                workingDirectoryPath: paths.root.path,
                environment: FlutterToolchainProcessEnvironment.make(
                    sdkRootPath: paths.root.path
                ),
                timeoutSeconds: 30
            )
        )

        guard !result.timedOut else {
            throw FlutterMaterializationError.commandTimedOut(
                .inspectToolchain
            )
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
}

enum FlutterToolchainProcessEnvironment {
    static func make(
        sdkRootPath: String,
        inherited: [String: String] =
            ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var environment = [
            "PATH":
                sdkRootPath
                    + "/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "CI": "true",
            "TERM": "dumb",
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8",
            "PUB_ENVIRONMENT": "appforge"
        ]

        for key in ["HOME", "TMPDIR"] {
            if let value = inherited[key],
               !value.isEmpty
            {
                environment[key] = value
            }
        }

        return environment
    }
}

private struct FlutterSDKPaths {
    let root: URL
    let executable: URL
}
