import AppForgeDomain
import Foundation

struct ExecutableToolDetector {
    func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) -> ToolDetectionResult {
        guard let candidate = candidate(for: requirement.id, flutterSDKPath: flutterSDKPath) else {
            return SystemToolDetectionSupport.missingResult(requirement: requirement)
        }

        guard let arguments = candidate.versionArguments else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .ready,
                version: nil,
                path: candidate.path,
                detail: "Gefunden"
            )
        }

        let execution = SystemToolDetectionSupport.run(
            executablePath: candidate.executablePath,
            arguments: arguments
        )
        guard execution.exitCode == 0 else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: candidate.path,
                detail: execution.output.isEmpty ? "Werkzeug konnte nicht ausgeführt werden." : execution.output
            )
        }

        let version = SemanticVersion(parsing: execution.output)
        let availability: ToolAvailability = requirement.versionConstraint.accepts(version) ? .ready : .incompatible
        let detail = availability == .ready
            ? "Bereit"
            : SystemToolDetectionSupport.incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: candidate.path,
            detail: detail
        )
    }

    private func candidate(for identifier: ToolIdentifier, flutterSDKPath: String?) -> ToolCandidate? {
        switch identifier {
        case .git:
            executableCandidate(command: "git", arguments: ["--version"])
        case .flutter:
            flutterCandidate(preferredSDKPath: flutterSDKPath)
        case .xcode, .androidSDK:
            nil
        case .java:
            executableCandidate(command: "java", arguments: ["-version"])
        case .vsCode:
            applicationCandidate(
                applicationPath: "/Applications/Visual Studio Code.app",
                command: "code",
                arguments: ["--version"]
            )
        case .androidStudio:
            applicationCandidate(
                applicationPath: "/Applications/Android Studio.app",
                command: nil,
                arguments: nil
            )
        case .xcodeGen:
            executableCandidate(command: "xcodegen", arguments: ["--version"])
        case .supabaseCLI:
            executableCandidate(command: "supabase", arguments: ["--version"])
        case .docker:
            executableCandidate(command: "docker", arguments: ["--version"])
        case .nix:
            executableCandidate(command: "nix", arguments: ["--version"])
        }
    }

    private func flutterCandidate(preferredSDKPath: String?) -> ToolCandidate? {
        if let preferredSDKPath, !preferredSDKPath.isEmpty {
            let sdkRoot = NSString(string: preferredSDKPath).expandingTildeInPath
            let executable = URL(fileURLWithPath: sdkRoot)
                .appendingPathComponent("bin")
                .appendingPathComponent("flutter")
                .path

            guard FileManager.default.isExecutableFile(atPath: executable) else { return nil }
            return ToolCandidate(path: sdkRoot, executablePath: executable, versionArguments: ["--version"])
        }

        return executableCandidate(command: "flutter", arguments: ["--version"])
    }

    private func applicationCandidate(
        applicationPath: String,
        command: String?,
        arguments: [String]?
    ) -> ToolCandidate? {
        if let command, let executable = SystemToolDetectionSupport.executablePath(for: command) {
            return ToolCandidate(path: executable, executablePath: executable, versionArguments: arguments)
        }

        guard FileManager.default.fileExists(atPath: applicationPath) else { return nil }
        return ToolCandidate(path: applicationPath, executablePath: applicationPath, versionArguments: nil)
    }

    private func executableCandidate(command: String, arguments: [String]) -> ToolCandidate? {
        guard let path = SystemToolDetectionSupport.executablePath(for: command) else { return nil }
        return ToolCandidate(path: path, executablePath: path, versionArguments: arguments)
    }
}
