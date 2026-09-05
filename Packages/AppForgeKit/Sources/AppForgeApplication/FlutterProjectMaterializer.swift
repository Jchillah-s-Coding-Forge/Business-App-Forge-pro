import AppForgeCore
import AppForgeDomain
import CryptoKit
import Foundation

public struct FlutterMaterializationResult: Equatable, Sendable {
    public let projectPath: String
    public let receipt: FlutterToolchainReceipt

    public init(
        projectPath: String,
        receipt: FlutterToolchainReceipt
    ) {
        self.projectPath = projectPath
        self.receipt = receipt
    }
}

public struct MaterializeFlutterProjectUseCase: Sendable {
    private let specificationValidator: ProjectSpecificationValidator
    private let renderer: any FlutterProjectRendering
    private let inspector: any FlutterToolchainInspecting
    private let runner: any ToolchainCommandRunning

    public init(
        specificationValidator: ProjectSpecificationValidator = ProjectSpecificationValidator(),
        renderer: any FlutterProjectRendering = DeterministicFlutterProjectRenderer(),
        inspector: any FlutterToolchainInspecting = SystemFlutterToolchainInspector(),
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner()
    ) {
        self.specificationValidator = specificationValidator
        self.renderer = renderer
        self.inspector = inspector
        self.runner = runner
    }

    public func callAsFunction(
        specification: ProjectSpecification,
        graph: ResolvedProductGraph,
        lockfile: ForgeLockfile,
        plan: GenerationPlan,
        flutterSDKPath: String,
        targetURL: URL
    ) throws -> FlutterMaterializationResult {
        let issues = specificationValidator.validate(specification)
        guard issues.isEmpty else {
            throw FlutterMaterializationError.invalidSpecification(issues)
        }

        let expectedPlan = try renderer.makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )
        guard expectedPlan == plan else {
            throw FlutterMaterializationError.generationPlanMismatch
        }

        let target = targetURL.standardizedFileURL
        let parent = target.deletingLastPathComponent()
        try validateTargetParent(parent)
        try ensureTargetIsAvailable(target)

        let inspection = try inspector.inspect(
            sdkRootPath: flutterSDKPath
        )

        let stagingRoot = parent.appendingPathComponent(
            ".appforge-materialize-\(UUID().uuidString)",
            isDirectory: true
        )
        let stagedProject = stagingRoot.appendingPathComponent(
            "project",
            isDirectory: true
        )

        do {
            try FileManager.default.createDirectory(
                at: stagingRoot,
                withIntermediateDirectories: false
            )

            let packageName = try FlutterDartNaming.packageName(
                from: specification.identity.name
            )
            let platformNames = try flutterPlatformNames(
                specification.targetPlatforms
            )
            let environment = FlutterToolchainProcessEnvironment.make(
                sdkRootPath: inspection.sdkRootPath
            )

            try runStep(
                .create,
                inspection: inspection,
                arguments: [
                    "--no-version-check",
                    "create",
                    "--empty",
                    "--no-pub",
                    "--project-name",
                    packageName,
                    "--org",
                    specification.identity.organizationIdentifier,
                    "--platforms",
                    platformNames.joined(separator: ","),
                    "project"
                ],
                workingDirectory: stagingRoot,
                environment: environment,
                timeoutSeconds: 120
            )

            try validateCreatedProject(stagedProject)
            try pruneBootstrapApplicationFiles(stagedProject)
            try GenerationPlanFileWriter().write(
                plan: plan,
                into: stagedProject
            )

            try runStep(
                .pubGet,
                inspection: inspection,
                arguments: ["--no-version-check", "pub", "get"],
                workingDirectory: stagedProject,
                environment: environment,
                timeoutSeconds: 300
            )
            try runStep(
                .analyze,
                inspection: inspection,
                arguments: ["--no-version-check", "analyze"],
                workingDirectory: stagedProject,
                environment: environment,
                timeoutSeconds: 300
            )
            try runStep(
                .test,
                inspection: inspection,
                arguments: ["--no-version-check", "test"],
                workingDirectory: stagedProject,
                environment: environment,
                timeoutSeconds: 600
            )

            let lockHash = try pubspecLockHash(in: stagedProject)
            let receipt = FlutterToolchainReceipt(
                flutter: inspection.identity,
                projectPackageName: packageName,
                organizationIdentifier: specification.identity.organizationIdentifier,
                targetPlatforms: sortedPlatforms(specification.targetPlatforms),
                pubspecLockSHA256: lockHash,
                validatedSteps: [
                    .inspectToolchain,
                    .create,
                    .pubGet,
                    .analyze,
                    .test
                ]
            )
            try writeReceipt(receipt, into: stagedProject)

            try ensureTargetIsAvailable(target)
            try FileManager.default.moveItem(
                at: stagedProject,
                to: target
            )
            try? FileManager.default.removeItem(at: stagingRoot)

            return FlutterMaterializationResult(
                projectPath: target.path,
                receipt: receipt
            )
        } catch {
            do {
                try cleanup(stagingRoot)
            } catch let cleanupError {
                let message = "Flutter-Materialisierung fehlgeschlagen und das Staging-Verzeichnis "
                    + "konnte nicht vollständig entfernt werden. Ursprünglicher Fehler: "
                    + error.localizedDescription
                    + " Cleanup-Fehler: "
                    + cleanupError.localizedDescription
                throw AppForgeError.fileSystem(message: message)
            }
            throw error
        }
    }

    private func runStep(
        _ step: FlutterMaterializationStep,
        inspection: FlutterToolchainInspection,
        arguments: [String],
        workingDirectory: URL,
        environment: [String: String],
        timeoutSeconds: TimeInterval
    ) throws {
        let result = try runner.run(
            ToolchainCommandRequest(
                executablePath: inspection.flutterExecutablePath,
                arguments: arguments,
                workingDirectoryPath: workingDirectory.path,
                environment: environment,
                timeoutSeconds: timeoutSeconds
            )
        )

        guard !result.timedOut else {
            throw FlutterMaterializationError.commandTimedOut(step)
        }
        guard result.exitCode == 0 else {
            throw FlutterMaterializationError.commandFailed(
                step: step,
                exitCode: result.exitCode,
                output: result.output
            )
        }
    }

    private func validateTargetParent(
        _ parent: URL
    ) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: parent.path,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue
        else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Flutter-Materialisierung existiert nicht."
            )
        }
        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw AppForgeError.fileSystem(
                message: "Der Zielordner für die Flutter-Materialisierung ist nicht beschreibbar."
            )
        }
    }

    private func ensureTargetIsAvailable(
        _ target: URL
    ) throws {
        guard !FileManager.default.fileExists(atPath: target.path) else {
            throw FlutterMaterializationError.targetAlreadyExists
        }
    }

    private func validateCreatedProject(
        _ projectURL: URL
    ) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(
            atPath: projectURL.path,
            isDirectory: &isDirectory
        ),
              isDirectory.boolValue
        else {
            throw AppForgeError.generation(
                message: "Flutter hat keinen vollständigen Projektordner erzeugt."
            )
        }
    }

    private func pruneBootstrapApplicationFiles(
        _ projectURL: URL
    ) throws {
        let fileManager = FileManager.default
        let relativePaths = [
            "lib",
            "test",
            "analysis_options.yaml",
            "pubspec.lock",
            ".dart_tool"
        ]

        for relativePath in relativePaths {
            let url = projectURL.appendingPathComponent(relativePath)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    private func pubspecLockHash(
        in projectURL: URL
    ) throws -> String {
        let lockURL = projectURL.appendingPathComponent("pubspec.lock")
        guard FileManager.default.fileExists(atPath: lockURL.path) else {
            throw FlutterMaterializationError.missingPubspecLock
        }

        let data = try Data(contentsOf: lockURL)
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func writeReceipt(
        _ receipt: FlutterToolchainReceipt,
        into projectURL: URL
    ) throws {
        let data = try FlutterToolchainReceiptCodec().encode(receipt)
        let receiptURL = projectURL.appendingPathComponent(
            FlutterToolchainReceipt.defaultFileName
        )
        try data.write(to: receiptURL, options: .atomic)
    }

    private func flutterPlatformNames(
        _ platforms: Set<TargetPlatform>
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

    private func sortedPlatforms(
        _ platforms: Set<TargetPlatform>
    ) -> [TargetPlatform] {
        platforms.sorted { lhs, rhs in
            platformSortKey(lhs) < platformSortKey(rhs)
        }
    }

    private func platformSortKey(
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

    private func cleanup(
        _ stagingRoot: URL
    ) throws {
        guard FileManager.default.fileExists(atPath: stagingRoot.path) else {
            return
        }
        try FileManager.default.removeItem(at: stagingRoot)
    }
}
