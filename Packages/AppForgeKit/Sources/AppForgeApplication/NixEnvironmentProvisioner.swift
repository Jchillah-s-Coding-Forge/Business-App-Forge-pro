import AppForgeDomain
import Foundation

public struct NixEnvironmentProvisioningInput: Equatable, Sendable {
    public let plan: NixEnvironmentPlan
    public let nixExecutablePath: String
    public let targetURL: URL

    public init(
        plan: NixEnvironmentPlan,
        nixExecutablePath: String,
        targetURL: URL
    ) {
        self.plan = plan
        self.nixExecutablePath = nixExecutablePath
        self.targetURL = targetURL
    }
}

public struct NixEnvironmentProvisioningResult: Equatable, Sendable {
    public let environmentPath: String
    public let receipt: NixEnvironmentReceipt

    public init(
        environmentPath: String,
        receipt: NixEnvironmentReceipt
    ) {
        self.environmentPath = environmentPath
        self.receipt = receipt
    }
}

public struct ProvisionNixEnvironmentUseCase: Sendable {
    private static let minimumNixVersion = SemanticVersion(
        major: 2,
        minor: 4
    )

    private let runner: any ToolchainCommandRunning
    private let renderer: NixFlakeRenderer
    private let lockInspector: NixFlakeLockInspector

    public init(
        runner: any ToolchainCommandRunning = SystemToolchainCommandRunner(),
        renderer: NixFlakeRenderer = NixFlakeRenderer()
    ) {
        self.runner = runner
        self.renderer = renderer
        lockInspector = NixFlakeLockInspector()
    }

    public func callAsFunction(
        _ input: NixEnvironmentProvisioningInput
    ) throws -> NixEnvironmentProvisioningResult {
        guard input.nixExecutablePath.hasPrefix("/") else {
            throw NixEnvironmentError.invalidNixExecutable
        }

        let workspace = try NixEnvironmentWorkspace.create(
            targetURL: input.targetURL
        )

        do {
            return try provision(input, workspace: workspace)
        } catch {
            try workspace.fail(with: error)
        }
    }

    private func provision(
        _ input: NixEnvironmentProvisioningInput,
        workspace: NixEnvironmentWorkspace
    ) throws -> NixEnvironmentProvisioningResult {
        try workspace.writeFlake(renderer.render(input.plan))

        let commands = NixEnvironmentCommandBuilder(
            nixExecutablePath: input.nixExecutablePath,
            workingDirectory: workspace.environmentURL,
            environment: NixProcessEnvironment.make()
        )

        let nixVersionResult = try execute(
            commands.versionRequest(),
            commandName: "nix --version"
        )
        let nixVersion = try validateNixVersion(
            nixVersionResult.output
        )

        _ = try execute(
            commands.lockRequest(),
            commandName: "nix flake lock"
        )

        let lock = try lockInspector.inspect(
            lockFileURL: workspace.lockFileURL()
        )

        let flutterResult = try execute(
            commands.flutterValidationRequest(),
            commandName: "nix develop --command flutter --version"
        )
        let flutterVersion = try validationVersion(
            flutterResult.output
        )

        let receipt = NixEnvironmentReceipt(
            nixVersion: nixVersion.description,
            nixpkgsLockedRevision: lock.nixpkgsRevision,
            flakeLockSHA256: lock.sha256,
            systems: input.plan.systems,
            packages: input.plan.packages,
            validationTool: "flutter",
            validationVersion: flutterVersion.description
        )
        try workspace.writeReceipt(receipt)
        let finalURL = try workspace.publish()

        return NixEnvironmentProvisioningResult(
            environmentPath: finalURL.path,
            receipt: receipt
        )
    }

    private func execute(
        _ request: ToolchainCommandRequest,
        commandName: String
    ) throws -> ToolchainCommandResult {
        let result = try runner.run(request)
        if result.timedOut {
            throw NixEnvironmentError.commandTimedOut(commandName)
        }
        guard result.exitCode == 0 else {
            throw NixEnvironmentError.commandFailed(
                command: commandName,
                exitCode: result.exitCode,
                output: result.output
            )
        }
        return result
    }

    private func validateNixVersion(
        _ output: String
    ) throws -> SemanticVersion {
        guard let version = SemanticVersion(parsing: output) else {
            throw NixEnvironmentError.incompatibleNixVersion(
                actual: output,
                minimum: Self.minimumNixVersion.description
            )
        }
        guard version >= Self.minimumNixVersion else {
            throw NixEnvironmentError.incompatibleNixVersion(
                actual: version.description,
                minimum: Self.minimumNixVersion.description
            )
        }
        return version
    }

    private func validationVersion(
        _ output: String
    ) throws -> SemanticVersion {
        guard let version = SemanticVersion(parsing: output) else {
            throw NixEnvironmentError.commandFailed(
                command: "flutter --version",
                exitCode: 0,
                output: output
            )
        }
        return version
    }
}
