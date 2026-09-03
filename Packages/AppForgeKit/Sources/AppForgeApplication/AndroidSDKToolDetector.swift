import AppForgeDomain
import Foundation

struct AndroidSDKToolDetector {
    func detect(requirement: ToolRequirement) -> ToolDetectionResult {
        guard let root = androidSDKRoot() else {
            return SystemToolDetectionSupport.missingResult(requirement: requirement)
        }

        let rootURL = URL(fileURLWithPath: root, isDirectory: true)
        let missingComponents = missingComponents(in: rootURL)
        guard missingComponents.isEmpty else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: root,
                detail: "Android SDK unvollständig. Fehlt: \(missingComponents.joined(separator: ", "))."
            )
        }

        return validatePlatformTools(requirement: requirement, rootURL: rootURL)
    }

    private func validatePlatformTools(
        requirement: ToolRequirement,
        rootURL: URL
    ) -> ToolDetectionResult {
        let adbURL = rootURL.appendingPathComponent("platform-tools/adb")
        let execution = SystemToolDetectionSupport.run(
            executablePath: adbURL.path,
            arguments: ["version"]
        )
        guard execution.exitCode == 0 else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: rootURL.path,
                detail: execution.output.isEmpty
                    ? "Android Platform Tools konnten nicht ausgeführt werden."
                    : execution.output
            )
        }

        let version = androidPlatformToolsVersion(output: execution.output)
        let availability: ToolAvailability = requirement.versionConstraint.accepts(version) ? .ready : .incompatible
        let detail = availability == .ready
            ? "Bereit – Platform Tools, Command-line Tools, Build Tools, Plattform und Lizenzen erkannt."
            : SystemToolDetectionSupport.incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: rootURL.path,
            detail: detail
        )
    }

    private func missingComponents(in rootURL: URL) -> [String] {
        var missing: [String] = []

        if !FileManager.default.isExecutableFile(atPath: rootURL.appendingPathComponent("platform-tools/adb").path) {
            missing.append("Platform Tools")
        }
        if androidSDKManagerPath(rootURL: rootURL) == nil {
            missing.append("Command-line Tools")
        }
        if !directoryContainsEntries(rootURL.appendingPathComponent("build-tools")) {
            missing.append("Build Tools")
        }
        if !directoryContainsAndroidPlatform(rootURL.appendingPathComponent("platforms")) {
            missing.append("Android Platform")
        }
        if !directoryContainsEntries(rootURL.appendingPathComponent("licenses")) {
            missing.append("SDK-Lizenzen")
        }

        return missing
    }

    private func androidSDKRoot() -> String? {
        let environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let roots = [
            environment["ANDROID_SDK_ROOT"],
            environment["ANDROID_HOME"],
            "\(home)/Library/Android/sdk"
        ].compactMap(\.self)

        for root in roots {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: root, isDirectory: &isDirectory), isDirectory.boolValue {
                return root
            }
        }

        return nil
    }

    private func androidSDKManagerPath(rootURL: URL) -> String? {
        let commandLineToolsURL = rootURL.appendingPathComponent("cmdline-tools", isDirectory: true)
        let latestURL = commandLineToolsURL.appendingPathComponent("latest/bin/sdkmanager")
        if FileManager.default.isExecutableFile(atPath: latestURL.path) {
            return latestURL.path
        }

        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: commandLineToolsURL,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        for entry in entries.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
            let candidate = entry.appendingPathComponent("bin/sdkmanager")
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate.path
            }
        }

        return nil
    }

    private func directoryContainsEntries(_ url: URL) -> Bool {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return entries.contains { !$0.hasPrefix(".") }
    }

    private func directoryContainsAndroidPlatform(_ url: URL) -> Bool {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: url.path) else {
            return false
        }
        return entries.contains { $0.hasPrefix("android-") }
    }

    private func androidPlatformToolsVersion(output: String) -> SemanticVersion? {
        let versionLine = output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first { $0.hasPrefix("Version ") }

        guard let versionLine else { return nil }
        return SemanticVersion(parsing: versionLine)
    }
}
