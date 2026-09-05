import AppForgeDomain
import Foundation

struct NixFlutterToolchainInspection: Equatable, Sendable {
    let environmentPath: String
    let nixExecutablePath: String
    let identity: FlutterToolchainIdentity
    let provenance: FlutterNixEnvironmentProvenance
}

protocol NixFlutterToolchainInspecting: Sendable {
    func inspect(
        environmentPath: String,
        nixExecutablePath: String
    ) throws -> NixFlutterToolchainInspection
}

struct SystemNixFlutterToolchainInspector: NixFlutterToolchainInspecting {
    private let runner: any ToolchainCommandRunning
    private let verifier: NixFlutterEnvironmentVerifier
    private let parser: FlutterToolchainIdentityParser

    init(
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner()
    ) {
        self.runner = runner
        verifier = NixFlutterEnvironmentVerifier()
        parser = FlutterToolchainIdentityParser()
    }

    func inspect(
        environmentPath: String,
        nixExecutablePath: String
    ) throws -> NixFlutterToolchainInspection {
        guard nixExecutablePath.hasPrefix("/") else {
            throw FlutterMaterializationError.invalidNixEnvironment
        }

        let verified = try verifier.verify(
            environmentPath: environmentPath
        )
        let environmentURL = URL(
            fileURLWithPath: verified.environmentPath,
            isDirectory: true
        )

        let nixVersion = try run(
            executablePath: nixExecutablePath,
            arguments: ["--version"],
            workingDirectory: environmentURL,
            timeoutSeconds: 30
        )
        try validateNixVersion(nixVersion.output)

        let flutterResult = try run(
            executablePath: nixExecutablePath,
            arguments: nixDevelopArguments(
                environmentPath: verified.environmentPath,
                flutterArguments: [
                    "--no-version-check",
                    "--version",
                    "--machine"
                ]
            ),
            workingDirectory: environmentURL,
            timeoutSeconds: 120
        )
        let identity = try parser.parse(
            flutterResult.output
        )
        try validateReceiptIdentity(
            identity,
            receipt: verified.receipt
        )

        return NixFlutterToolchainInspection(
            environmentPath: verified.environmentPath,
            nixExecutablePath: nixExecutablePath,
            identity: identity,
            provenance: verified.provenance
        )
    }

    private func run(
        executablePath: String,
        arguments: [String],
        workingDirectory: URL,
        timeoutSeconds: TimeInterval
    ) throws -> ToolchainCommandResult {
        let result = try runner.run(
            ToolchainCommandRequest(
                executablePath: executablePath,
                arguments: arguments,
                workingDirectoryPath: workingDirectory.path,
                environment: NixProcessEnvironment.make(),
                timeoutSeconds: timeoutSeconds
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

    private func validateNixVersion(
        _ output: String
    ) throws {
        let minimum = SemanticVersion(major: 2, minor: 4)
        guard let version = SemanticVersion(parsing: output) else {
            throw FlutterMaterializationError.invalidNixEnvironment
        }
        guard version >= minimum else {
            throw NixEnvironmentError.incompatibleNixVersion(
                actual: version.description,
                minimum: minimum.description
            )
        }
    }

    private func validateReceiptIdentity(
        _ identity: FlutterToolchainIdentity,
        receipt: NixEnvironmentReceipt
    ) throws {
        guard receipt.validationTool == "flutter",
              let validated = SemanticVersion(
                  parsing: receipt.validationVersion
              ),
              let actual = SemanticVersion(
                  parsing: identity.flutterVersion
              ),
              validated == actual
        else {
            throw FlutterMaterializationError.nixEnvironmentReceiptMismatch
        }
    }
}

func nixDevelopArguments(
    environmentPath: String,
    flutterArguments: [String]
) -> [String] {
    [
        "--extra-experimental-features",
        "nix-command flakes",
        "develop",
        environmentPath,
        "--command",
        "flutter"
    ] + flutterArguments
}
