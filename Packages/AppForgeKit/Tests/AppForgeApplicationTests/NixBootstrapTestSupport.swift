import AppForgeApplication
import AppForgeDomain
import Foundation

enum NixBootstrapTestSupport {
    static func installer(
        policy: NixBootstrapReleasePolicy = .current
    ) -> Data {
        Data(
            """
            #!/bin/sh
            version=\(policy.version)
            x86_path=nix-\(policy.version)-x86_64-darwin.tar.xz
            x86_hash=\(policy.x86DarwinTarballSHA256)
            arm_path=nix-\(policy.version)-aarch64-darwin.tar.xz
            arm_hash=\(policy.aarch64DarwinTarballSHA256)
            url=https://releases.nixos.org/nix/nix-\(policy.version)/nix-\(policy.version)-$system.tar.xz
            """.utf8
        )
    }

    static func download(
        data: Data? = nil,
        responseURL: URL? = nil,
        statusCode: Int = 200,
        policy: NixBootstrapReleasePolicy = .current
    ) -> NixInstallerDownload {
        NixInstallerDownload(
            data: data ?? installer(policy: policy),
            responseURL: responseURL
                ?? URL(string: policy.installerURLString)
                ?? URL(fileURLWithPath: "/invalid-nix-policy-url"),
            statusCode: statusCode
        )
    }

    static func temporaryDirectory(
        prefix: String = "appforge-nix-bootstrap-tests"
    ) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(prefix)-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }

    static func bootstrapDirectories(
        in parent: URL
    ) -> [URL] {
        let contents = (
            try? FileManager.default.contentsOfDirectory(
                at: parent,
                includingPropertiesForKeys: nil
            )
        ) ?? []
        return contents.filter {
            $0.lastPathComponent.hasPrefix(
                ".appforge-nix-bootstrap-"
            )
        }
    }
}

final class StubNixInstallerDownloader: NixInstallerDownloading, @unchecked Sendable {
    let result: NixInstallerDownload
    private(set) var requestedURLs: [URL] = []

    init(result: NixInstallerDownload) {
        self.result = result
    }

    func download(
        from url: URL
    ) async throws -> NixInstallerDownload {
        requestedURLs.append(url)
        return result
    }
}

final class RecordingNixBootstrapLauncher: NixBootstrapTerminalLaunching, @unchecked Sendable {
    private(set) var commandURLs: [URL] = []

    func launch(
        commandURL: URL
    ) throws {
        commandURLs.append(commandURL)
    }
}
