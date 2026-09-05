import AppForgeDomain
import Foundation

public protocol NixBootstrapPreparing: Sendable {
    func prepare(
        workspaceParentURL: URL
    ) async throws -> NixBootstrapPreparedInstaller
}

public protocol NixBootstrapLaunching: Sendable {
    func launch(
        prepared: NixBootstrapPreparedInstaller,
        confirmation: NixBootstrapConfirmation
    ) throws
}

public protocol NixBootstrapCleaning: Sendable {
    func cleanup(
        prepared: NixBootstrapPreparedInstaller
    ) throws
}

public protocol NixEnvironmentProvisioning: Sendable {
    func provision(
        _ input: NixEnvironmentProvisioningInput
    ) throws -> NixEnvironmentProvisioningResult
}

extension PrepareNixBootstrapUseCase: NixBootstrapPreparing {
    public func prepare(
        workspaceParentURL: URL
    ) async throws -> NixBootstrapPreparedInstaller {
        try await self(
            workspaceParentURL: workspaceParentURL
        )
    }
}

extension LaunchNixBootstrapUseCase: NixBootstrapLaunching {
    public func launch(
        prepared: NixBootstrapPreparedInstaller,
        confirmation: NixBootstrapConfirmation
    ) throws {
        try self(
            prepared: prepared,
            confirmation: confirmation
        )
    }
}

extension CleanupNixBootstrapUseCase: NixBootstrapCleaning {
    public func cleanup(
        prepared: NixBootstrapPreparedInstaller
    ) throws {
        try self(prepared: prepared)
    }
}

extension ProvisionNixEnvironmentUseCase: NixEnvironmentProvisioning {
    public func provision(
        _ input: NixEnvironmentProvisioningInput
    ) throws -> NixEnvironmentProvisioningResult {
        try self(input)
    }
}
