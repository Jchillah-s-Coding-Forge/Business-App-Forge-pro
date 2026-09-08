import AppForgeApplication
import AppForgeDomain
import Foundation

struct GenerationFixture {
    let specification: ProjectSpecification
    let graph: ResolvedProductGraph
    let lockfile: ForgeLockfile
    let plan: GenerationPlan
}

final class RecordingFlutterInspector: FlutterToolchainInspecting, @unchecked Sendable {
    private(set) var sdkPaths: [String] = []

    func inspect(
        sdkRootPath: String
    ) throws -> FlutterToolchainInspection {
        sdkPaths.append(sdkRootPath)
        return FlutterToolchainInspection(
            sdkRootPath: "/validated/flutter",
            flutterExecutablePath: "/validated/flutter/bin/flutter",
            dartExecutablePath: "/validated/flutter/bin/dart",
            identity: FlutterToolchainIdentity(
                flutterVersion: "3.47.2",
                channel: "stable",
                frameworkRevision: String(repeating: "a", count: 40),
                engineRevision: String(repeating: "b", count: 40),
                dartSDKVersion: "3.11.0"
            )
        )
    }
}

final class MaterializationToolchainRunner: ToolchainCommandRunning, @unchecked Sendable {
    private let failingStep: FlutterMaterializationStep?
    private(set) var requests: [ToolchainCommandRequest] = []

    init(failingStep: FlutterMaterializationStep? = nil) {
        self.failingStep = failingStep
    }

    func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        requests.append(request)
        let currentStep = step(for: request.arguments)

        if currentStep == .create {
            try createBootstrapProject(
                in: URL(
                    fileURLWithPath: request.workingDirectoryPath,
                    isDirectory: true
                )
            )
        }

        if failingStep == currentStep {
            return ToolchainCommandResult(
                exitCode: 2,
                output: "simulated \(currentStep.rawValue) failure",
                timedOut: false
            )
        }

        if currentStep == .pubGet {
            try writePubspecLock(
                in: URL(
                    fileURLWithPath: request.workingDirectoryPath,
                    isDirectory: true
                )
            )
        }

        return ToolchainCommandResult(
            exitCode: 0,
            output: "",
            timedOut: false
        )
    }

    private func step(
        for arguments: [String]
    ) -> FlutterMaterializationStep {
        if arguments.contains("create") {
            return .create
        }
        if arguments.contains("analyze") {
            return .analyze
        }
        if arguments.contains("format") {
            return .format
        }
        if arguments.contains("test") {
            return .test
        }
        return .pubGet
    }

    private func createBootstrapProject(
        in stagingRoot: URL
    ) throws {
        let projectURL = stagingRoot.appendingPathComponent(
            "project",
            isDirectory: true
        )
        try createBootstrapDirectories(in: projectURL)
        try writeBootstrapFiles(in: projectURL)
    }

    private func createBootstrapDirectories(
        in projectURL: URL
    ) throws {
        for relativePath in [
            "ios/Runner.xcodeproj",
            "android/app",
            "lib",
            "test"
        ] {
            try FileManager.default.createDirectory(
                at: projectURL.appendingPathComponent(
                    relativePath,
                    isDirectory: true
                ),
                withIntermediateDirectories: true
            )
        }
    }

    private func writeBootstrapFiles(
        in projectURL: URL
    ) throws {
        let files = [
            ("lib/main.dart", "bootstrap"),
            ("test/widget_test.dart", "bootstrap"),
            (
                "analysis_options.yaml",
                "include: package:flutter_lints/flutter.yaml\n"
            ),
            ("pubspec.lock", "bootstrap lock")
        ]

        for (relativePath, contents) in files {
            try contents.write(
                to: projectURL.appendingPathComponent(relativePath),
                atomically: true,
                encoding: .utf8
            )
        }
    }

    private func writePubspecLock(
        in projectURL: URL
    ) throws {
        try "packages:\n  flutter: sdk\n".write(
            to: projectURL.appendingPathComponent("pubspec.lock"),
            atomically: true,
            encoding: .utf8
        )
    }
}
