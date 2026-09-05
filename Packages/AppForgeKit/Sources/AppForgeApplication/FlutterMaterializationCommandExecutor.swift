import AppForgeDomain
import Foundation

struct FlutterMaterializationCommandExecutor {
    let inspection: FlutterToolchainInspection
    let runner: any ToolchainCommandRunning
    let environment: [String: String]

    init(
        inspection: FlutterToolchainInspection,
        runner: any ToolchainCommandRunning
    ) {
        self.inspection = inspection
        self.runner = runner
        environment = FlutterToolchainProcessEnvironment.make(
            sdkRootPath: inspection.sdkRootPath
        )
    }

    func createProject(
        packageName: String,
        organizationIdentifier: String,
        platformNames: [String],
        in stagingRoot: URL
    ) throws {
        try execute(
            FlutterMaterializationInvocation(
                step: .create,
                arguments: [
                    "--no-version-check",
                    "create",
                    "--empty",
                    "--no-pub",
                    "--project-name",
                    packageName,
                    "--org",
                    organizationIdentifier,
                    "--platforms",
                    platformNames.joined(separator: ","),
                    "project"
                ],
                workingDirectory: stagingRoot,
                timeoutSeconds: 120
            )
        )
    }

    func resolveDependencies(
        in projectURL: URL
    ) throws {
        try execute(
            FlutterMaterializationInvocation(
                step: .pubGet,
                arguments: ["--no-version-check", "pub", "get"],
                workingDirectory: projectURL,
                timeoutSeconds: 300
            )
        )
    }

    func analyze(
        projectURL: URL
    ) throws {
        try execute(
            FlutterMaterializationInvocation(
                step: .analyze,
                arguments: ["--no-version-check", "analyze"],
                workingDirectory: projectURL,
                timeoutSeconds: 300
            )
        )
    }

    func test(
        projectURL: URL
    ) throws {
        try execute(
            FlutterMaterializationInvocation(
                step: .test,
                arguments: ["--no-version-check", "test"],
                workingDirectory: projectURL,
                timeoutSeconds: 600
            )
        )
    }

    private func execute(
        _ invocation: FlutterMaterializationInvocation
    ) throws {
        let result = try runner.run(
            ToolchainCommandRequest(
                executablePath: inspection.flutterExecutablePath,
                arguments: invocation.arguments,
                workingDirectoryPath: invocation.workingDirectory.path,
                environment: environment,
                timeoutSeconds: invocation.timeoutSeconds
            )
        )

        guard !result.timedOut else {
            throw FlutterMaterializationError.commandTimedOut(
                invocation.step
            )
        }
        guard result.exitCode == 0 else {
            throw FlutterMaterializationError.commandFailed(
                step: invocation.step,
                exitCode: result.exitCode,
                output: result.output
            )
        }
    }
}

private struct FlutterMaterializationInvocation {
    let step: FlutterMaterializationStep
    let arguments: [String]
    let workingDirectory: URL
    let timeoutSeconds: TimeInterval
}

enum FlutterMaterializationPlatformMapper {
    static func sortedPlatforms(
        _ platforms: Set<TargetPlatform>
    ) -> [TargetPlatform] {
        platforms.sorted {
            sortKey($0) < sortKey($1)
        }
    }

    static func names(
        for platforms: Set<TargetPlatform>
    ) throws -> [String] {
        try sortedPlatforms(platforms).map { platform in
            switch platform {
            case .iOS:
                "ios"
            case .android:
                "android"
            case .web, .macOS, .windows, .linux:
                throw FlutterMaterializationError.unsupportedTargetPlatform(
                    platform
                )
            }
        }
    }

    private static func sortKey(
        _ platform: TargetPlatform
    ) -> Int {
        switch platform {
        case .android:
            0
        case .iOS:
            1
        case .web:
            2
        case .macOS:
            3
        case .windows:
            4
        case .linux:
            5
        }
    }
}
