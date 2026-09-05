import AppForgeDomain
import Foundation

struct NixEnvironmentCommandBuilder {
    let nixExecutablePath: String
    let workingDirectory: URL
    let environment: [String: String]

    func versionRequest() -> ToolchainCommandRequest {
        request(
            arguments: ["--version"],
            timeoutSeconds: 30
        )
    }

    func lockRequest() -> ToolchainCommandRequest {
        request(
            arguments: flakeArguments + ["flake", "lock"],
            timeoutSeconds: 300
        )
    }

    func flutterValidationRequest() -> ToolchainCommandRequest {
        request(
            arguments: flakeArguments + [
                "develop",
                "--command",
                "flutter",
                "--version"
            ],
            timeoutSeconds: 600
        )
    }

    private var flakeArguments: [String] {
        [
            "--extra-experimental-features",
            "nix-command flakes"
        ]
    }

    private func request(
        arguments: [String],
        timeoutSeconds: TimeInterval
    ) -> ToolchainCommandRequest {
        ToolchainCommandRequest(
            executablePath: nixExecutablePath,
            arguments: arguments,
            workingDirectoryPath: workingDirectory.path,
            environment: environment,
            timeoutSeconds: timeoutSeconds
        )
    }
}

enum NixProcessEnvironment {
    static func make(
        inherited: [String: String] = ProcessInfo.processInfo.environment
    ) -> [String: String] {
        var environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "CI": "true",
            "TERM": "dumb",
            "LANG": "en_US.UTF-8",
            "LC_ALL": "en_US.UTF-8"
        ]

        for key in ["HOME", "TMPDIR", "USER"] {
            if let value = inherited[key], !value.isEmpty {
                environment[key] = value
            }
        }

        return environment
    }
}
