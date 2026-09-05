import AppForgeApplication
import AppForgeDomain
import CryptoKit
import Foundation
import XCTest

struct NixFlutterMaterializationFixture {
    let rootURL: URL
    let environmentURL: URL
    let targetURL: URL
    let specification: ProjectSpecification
    let renderedProduct: FlutterRenderedProduct
    let nixpkgsRevision: String
    let flakeLockSHA256: String
}

enum NixFlutterMaterializerTestSupport {
    static func makeFixture(
        packages: [NixEnvironmentPackage] = [
            .flutter,
            .git,
            .jdk17
        ],
        receiptLockSHA256: String? = nil,
        receiptRevision: String? = nil
    ) throws -> NixFlutterMaterializationFixture {
        let rootURL = try temporaryDirectory()
        let environmentURL = rootURL.appendingPathComponent(
            "nix-environment",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: environmentURL,
            withIntermediateDirectories: false
        )

        let specification = makeSpecification()
        let renderedProduct = try makeRenderedProduct(
            specification: specification
        )
        let plan = NixEnvironmentPlan(
            systems: NixEnvironmentSystem.allCases,
            packages: packages,
            unmanagedRequirements: [.androidSDK, .xcode]
        )
        try NixFlakeRenderer().render(plan).write(
            to: environmentURL.appendingPathComponent(
                "flake.nix"
            ),
            atomically: true,
            encoding: .utf8
        )

        let revision = String(repeating: "a", count: 40)
        let lockData = Data(lockJSON(revision: revision).utf8)
        try lockData.write(
            to: environmentURL.appendingPathComponent(
                "flake.lock"
            ),
            options: .atomic
        )
        let lockSHA = sha256(lockData)

        let receipt = NixEnvironmentReceipt(
            nixVersion: "2.35.2",
            nixpkgsLockedRevision:
                receiptRevision ?? revision,
            flakeLockSHA256:
                receiptLockSHA256 ?? lockSHA,
            systems: plan.systems,
            packages: plan.packages,
            unmanagedRequirements: plan.unmanagedRequirements,
            validationTool: "flutter",
            validationVersion: "3.47.2"
        )
        let receiptData = try NixEnvironmentReceiptCodec()
            .encode(receipt)
        try receiptData.write(
            to: environmentURL.appendingPathComponent(
                NixEnvironmentReceipt.defaultFileName
            ),
            options: .atomic
        )

        return NixFlutterMaterializationFixture(
            rootURL: rootURL,
            environmentURL: environmentURL,
            targetURL: rootURL.appendingPathComponent(
                "materialized-app",
                isDirectory: true
            ),
            specification: specification,
            renderedProduct: renderedProduct,
            nixpkgsRevision: revision,
            flakeLockSHA256: lockSHA
        )
    }

    static func input(
        _ fixture: NixFlutterMaterializationFixture
    ) -> FlutterMaterializationInput {
        FlutterMaterializationInput(
            specification: fixture.specification,
            renderedProduct: fixture.renderedProduct,
            toolchain: .nixEnvironment(
                environmentPath: fixture.environmentURL.path,
                nixExecutablePath: "/nix/bin/nix"
            ),
            targetURL: fixture.targetURL
        )
    }

    static func stagingDirectories(
        in rootURL: URL
    ) -> [URL] {
        let contents = (
            try? FileManager.default.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: nil
            )
        ) ?? []

        return contents.filter {
            $0.lastPathComponent.hasPrefix(
                ".appforge-materialize-"
            )
        }
    }

    private static func makeRenderedProduct(
        specification: ProjectSpecification
    ) throws -> FlutterRenderedProduct {
        let version = try XCTUnwrap(
            ForgeSemanticVersion("1.0.0")
        )
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            supportedBackends: [.supabase],
            maturity: .stable,
            source: .bundled
        )
        let graph = ResolvedProductGraph(
            packages: [
                ResolvedPackage(contract: contract)
            ],
            capabilities: []
        )
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        let plan = try DeterministicFlutterProjectRenderer()
            .makePlan(
                specification: specification,
                graph: graph,
                lockfile: lockfile
            )

        return FlutterRenderedProduct(
            graph: graph,
            lockfile: lockfile,
            plan: plan
        )
    }

    private static func makeSpecification()
        -> ProjectSpecification
    {
        let asset = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.asset",
                code: "asset",
                label: "Asset"
            ),
            fields: [
                FieldDefinition(
                    identity: DefinitionIdentity(
                        id: "field.asset.name",
                        code: "name",
                        label: "Name"
                    ),
                    dataType: .string,
                    isRequired: true
                )
            ]
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Inventory App",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: [asset]
        )
    }

    private static func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "appforge-nix-materializer-tests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }

    private static func lockJSON(
        revision: String
    ) -> String {
        """
        {
          "nodes": {
            "nixpkgs": {
              "locked": {
                "lastModified": 1780000000,
                "narHash": "sha256-test",
                "owner": "NixOS",
                "repo": "nixpkgs",
                "rev": "\(revision)",
                "type": "github"
              }
            },
            "root": {
              "inputs": {
                "nixpkgs": "nixpkgs"
              }
            }
          },
          "root": "root",
          "version": 7
        }
        """
    }

    private static func sha256(
        _ data: Data
    ) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

final class NixMaterializationToolchainRunner: ToolchainCommandRunning, @unchecked Sendable {
    private(set) var requests: [ToolchainCommandRequest] = []

    func run(
        _ request: ToolchainCommandRequest
    ) throws -> ToolchainCommandResult {
        requests.append(request)

        if request.arguments == ["--version"] {
            return success(
                output: "nix (Nix) 2.35.2"
            )
        }

        if request.arguments.contains("--machine") {
            return success(
                output: flutterMachineVersion
            )
        }

        if request.arguments.contains("create") {
            try createBootstrapProject(
                workingDirectoryPath:
                    request.workingDirectoryPath
            )
        }

        if request.arguments.contains("pub"),
           request.arguments.contains("get")
        {
            try writePubspecLock(
                workingDirectoryPath:
                    request.workingDirectoryPath
            )
        }

        return success(output: "")
    }

    private func success(
        output: String
    ) -> ToolchainCommandResult {
        ToolchainCommandResult(
            exitCode: 0,
            output: output,
            timedOut: false
        )
    }

    private var flutterMachineVersion: String {
        """
        {
          "flutterVersion": "3.47.2",
          "channel": "stable",
          "frameworkRevision": "\(String(repeating: "b", count: 40))",
          "engineRevision": "\(String(repeating: "c", count: 40))",
          "dartSdkVersion": "3.11.0"
        }
        """
    }

    private func createBootstrapProject(
        workingDirectoryPath: String
    ) throws {
        let projectURL = URL(
            fileURLWithPath: workingDirectoryPath,
            isDirectory: true
        ).appendingPathComponent(
            "project",
            isDirectory: true
        )

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

        try writeBootstrapFiles(
            projectURL: projectURL
        )
    }

    private func writeBootstrapFiles(
        projectURL: URL
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
                to: projectURL.appendingPathComponent(
                    relativePath
                ),
                atomically: true,
                encoding: .utf8
            )
        }
    }

    private func writePubspecLock(
        workingDirectoryPath: String
    ) throws {
        let projectURL = URL(
            fileURLWithPath: workingDirectoryPath,
            isDirectory: true
        )
        try "packages:\n  flutter: sdk\n".write(
            to: projectURL.appendingPathComponent(
                "pubspec.lock"
            ),
            atomically: true,
            encoding: .utf8
        )
    }
}
