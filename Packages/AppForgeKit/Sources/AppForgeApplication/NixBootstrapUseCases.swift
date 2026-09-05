import AppForgeDomain
import Foundation

public struct PrepareNixBootstrapUseCase: Sendable {
    private let downloader: any NixInstallerDownloading
    private let policy: NixBootstrapReleasePolicy
    private let validator: NixInstallerValidator

    public init(
        downloader: any NixInstallerDownloading = URLSessionNixInstallerDownloader(),
        policy: NixBootstrapReleasePolicy = .current
    ) {
        self.downloader = downloader
        self.policy = policy
        validator = NixInstallerValidator()
    }

    public func callAsFunction(
        workspaceParentURL: URL
    ) async throws -> NixBootstrapPreparedInstaller {
        guard let installerURL = URL(
            string: policy.installerURLString
        ) else {
            throw NixBootstrapError.invalidReleaseURL
        }

        let download = try await downloader.download(
            from: installerURL
        )
        let validation = try validator.validate(
            download,
            policy: policy
        )
        let workspace = try NixBootstrapWorkspace.create(
            parentURL: workspaceParentURL
        )

        do {
            try workspace.write(
                installerData: download.data
            )
            return workspace.prepared(
                version: policy.version,
                sha256: validation.sha256
            )
        } catch {
            try? workspace.cleanup()
            throw error
        }
    }
}

public struct LaunchNixBootstrapUseCase: Sendable {
    private let launcher: any NixBootstrapTerminalLaunching
    private let policy: NixBootstrapReleasePolicy
    private let validator: NixInstallerValidator

    public init(
        launcher: any NixBootstrapTerminalLaunching = SystemNixBootstrapTerminalLauncher(),
        policy: NixBootstrapReleasePolicy = .current
    ) {
        self.launcher = launcher
        self.policy = policy
        validator = NixInstallerValidator()
    }

    public func callAsFunction(
        prepared: NixBootstrapPreparedInstaller,
        confirmation: NixBootstrapConfirmation
    ) throws {
        guard prepared.version == policy.version else {
            throw NixBootstrapError.releasePolicyMismatch
        }
        guard confirmation.approvedInstallerSHA256
            == prepared.installerSHA256
        else {
            throw NixBootstrapError.confirmationMismatch
        }

        let workspace = try NixBootstrapWorkspace.validate(
            prepared
        )
        guard try workspace.commandIsIntact() else {
            throw NixBootstrapError.invalidPreparedWorkspace
        }

        let installerData = try Data(
            contentsOf: workspace.installerURL
        )
        let download = try localDownload(installerData)
        let validation = try validator.validate(
            download,
            policy: policy
        )
        guard validation.sha256 == prepared.installerSHA256 else {
            throw NixBootstrapError.installerDigestMismatch
        }

        try launcher.launch(
            commandURL: workspace.commandURL
        )
    }

    private func localDownload(
        _ data: Data
    ) throws -> NixInstallerDownload {
        guard let url = URL(
            string: policy.installerURLString
        ) else {
            throw NixBootstrapError.invalidReleaseURL
        }
        return NixInstallerDownload(
            data: data,
            responseURL: url,
            statusCode: 200
        )
    }
}

public struct CleanupNixBootstrapUseCase: Sendable {
    public init() {}

    public func callAsFunction(
        prepared: NixBootstrapPreparedInstaller
    ) throws {
        let workspace = try NixBootstrapWorkspace.validate(
            prepared
        )
        try workspace.cleanup()
    }
}
