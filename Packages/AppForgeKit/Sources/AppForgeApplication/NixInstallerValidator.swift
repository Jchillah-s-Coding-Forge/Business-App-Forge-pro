import AppForgeDomain
import CryptoKit
import Foundation

struct NixInstallerValidation: Equatable, Sendable {
    let sha256: String
    let text: String
}

struct NixInstallerValidator: Sendable {
    func validate(
        _ download: NixInstallerDownload,
        policy: NixBootstrapReleasePolicy
    ) throws -> NixInstallerValidation {
        guard let expectedURL = URL(
            string: policy.installerURLString
        ) else {
            throw NixBootstrapError.invalidReleaseURL
        }
        guard isExpectedURL(
            download.responseURL,
            expected: expectedURL
        ) else {
            throw NixBootstrapError.unexpectedResponseURL
        }
        guard download.statusCode == 200 else {
            throw NixBootstrapError.invalidHTTPStatus(
                download.statusCode
            )
        }
        guard !download.data.isEmpty else {
            throw NixBootstrapError.emptyInstaller
        }
        guard download.data.count <= policy.maximumInstallerBytes else {
            throw NixBootstrapError.installerTooLarge(
                maximumBytes: policy.maximumInstallerBytes
            )
        }
        guard let text = String(
            data: download.data,
            encoding: .utf8
        ) else {
            throw NixBootstrapError.invalidInstallerEncoding
        }
        try validateStructure(text, policy: policy)

        return NixInstallerValidation(
            sha256: sha256(download.data),
            text: text
        )
    }

    func sha256(
        fileURL: URL
    ) throws -> String {
        sha256(try Data(contentsOf: fileURL))
    }

    private func validateStructure(
        _ text: String,
        policy: NixBootstrapReleasePolicy
    ) throws {
        let requiredMarkers = [
            "#!/bin/sh",
            "nix-\(policy.version)-x86_64-darwin.tar.xz",
            "nix-\(policy.version)-aarch64-darwin.tar.xz",
            policy.x86DarwinTarballSHA256,
            policy.aarch64DarwinTarballSHA256,
            "https://releases.nixos.org/nix/nix-\(policy.version)/"
        ]

        guard text.hasPrefix("#!/bin/sh\n"),
              requiredMarkers.allSatisfy(text.contains)
        else {
            throw NixBootstrapError.installerStructureMismatch
        }
    }

    private func isExpectedURL(
        _ actual: URL,
        expected: URL
    ) -> Bool {
        actual.scheme == "https"
            && actual.host == "releases.nixos.org"
            && actual.absoluteString == expected.absoluteString
    }

    private func sha256(
        _ data: Data
    ) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
