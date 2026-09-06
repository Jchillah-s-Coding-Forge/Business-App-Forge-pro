import AppForgeDomain
import Foundation

struct ExecutableToolDetector {
    private let applicationLocator: any MacOSApplicationLocating

    init(
        applicationLocator: any MacOSApplicationLocating =
            SystemMacOSApplicationLocator()
    ) {
        self.applicationLocator = applicationLocator
    }

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
            ideApplicationCandidate(.vsCode)
        case .androidStudio:
            ideApplicationCandidate(.androidStudio)
        case .xcodeGen:
            executableCandidate(command: "xcodegen", arguments: ["--version"])
        case .supabaseCLI:
            executableCandidate(command: "supabase", arguments: ["--version"])
        case .docker:
            executableCandidate(command: "docker", arguments: ["--version"])
        case .nix:
            nixCandidate()
        }
    }

    private func nixCandidate() -> ToolCandidate? {
        if let candidate = executableCandidate(
            command: "nix",
            arguments: ["--version"]
        ) {
            return candidate
        }

        let standardPath = "/nix/var/nix/profiles/default/bin/nix"
        guard FileManager.default.isExecutableFile(atPath: standardPath) else {
            return nil
        }
        return ToolCandidate(
            path: standardPath,
            executablePath: standardPath,
            versionArguments: ["--version"]
        )
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

    private func ideApplicationCandidate(
        _ ide: PreferredIDE
    ) -> ToolCandidate? {
        let descriptor = IDEApplicationDescriptor(
            ide: ide
        )
        guard let bundleIdentifier = descriptor.bundleIdentifier,
              let path = applicationLocator.locate(
                  bundleIdentifier: bundleIdentifier,
                  knownPaths: descriptor.knownPaths
              )
        else {
            return nil
        }

        return ToolCandidate(
            path: path,
            executablePath: path,
            versionArguments: nil
        )
    }

    private func executableCandidate(command: String, arguments: [String]) -> ToolCandidate? {
        guard let path = SystemToolDetectionSupport.executablePath(for: command) else { return nil }
        return ToolCandidate(path: path, executablePath: path, versionArguments: arguments)
    }
}
