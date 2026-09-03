import AppForgeDomain
import Foundation

public struct SystemToolDetector: ToolDetector {
    public init() {}

    public func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        switch requirement.id {
        case .xcode:
            detectXcode(requirement: requirement)
        case .androidSDK:
            detectAndroidSDK(requirement: requirement)
        default:
            detectExecutableTool(
                requirement: requirement,
                flutterSDKPath: flutterSDKPath
            )
        }
    }

    private func detectExecutableTool(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) -> ToolDetectionResult {
        guard let candidate = candidate(for: requirement.id, flutterSDKPath: flutterSDKPath) else {
            return missingResult(requirement: requirement)
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

        let execution = run(executablePath: candidate.executablePath, arguments: arguments)
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
        let detail = availability == .ready ? "Bereit" : incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: candidate.path,
            detail: detail
        )
    }

    private func detectXcode(requirement: ToolRequirement) -> ToolDetectionResult {
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/xcode-select") else {
            return missingResult(requirement: requirement)
        }

        let selection = run(executablePath: "/usr/bin/xcode-select", arguments: ["-p"])
        guard selection.exitCode == 0, !selection.output.isEmpty else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: nil,
                detail: "Xcode Command Line Tools sind nicht vollständig eingerichtet."
            )
        }

        guard selection.output.contains(".app/Contents/Developer") else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: selection.output,
                detail: "Command Line Tools sind aktiv, aber kein vollständiges Xcode ist ausgewählt."
            )
        }

        guard let xcodebuild = executablePath(for: "xcodebuild") else {
            return missingResult(requirement: requirement)
        }

        let execution = run(executablePath: xcodebuild, arguments: ["-version"])
        guard execution.exitCode == 0 else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: selection.output,
                detail: execution.output.isEmpty ? "Xcode konnte nicht validiert werden." : execution.output
            )
        }

        let version = SemanticVersion(parsing: execution.output)
        let availability: ToolAvailability = requirement.versionConstraint.accepts(version) ? .ready : .incompatible
        let detail = availability == .ready
            ? "Bereit – Xcode und Command Line Tools sind aktiv."
            : incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: selection.output,
            detail: detail
        )
    }

    private func detectAndroidSDK(requirement: ToolRequirement) -> ToolDetectionResult {
        guard let root = androidSDKRoot() else {
            return missingResult(requirement: requirement)
        }

        let rootURL = URL(fileURLWithPath: root, isDirectory: true)
        let adbURL = rootURL.appendingPathComponent("platform-tools/adb")
        var missingComponents: [String] = []

        if !FileManager.default.isExecutableFile(atPath: adbURL.path) {
            missingComponents.append("Platform Tools")
        }
        if androidSDKManagerPath(rootURL: rootURL) == nil {
            missingComponents.append("Command-line Tools")
        }
        if !directoryContainsEntries(rootURL.appendingPathComponent("build-tools")) {
            missingComponents.append("Build Tools")
        }
        if !directoryContainsAndroidPlatform(rootURL.appendingPathComponent("platforms")) {
            missingComponents.append("Android Platform")
        }
        if !directoryContainsEntries(rootURL.appendingPathComponent("licenses")) {
            missingComponents.append("SDK-Lizenzen")
        }

        guard missingComponents.isEmpty else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: root,
                detail: "Android SDK unvollständig. Fehlt: \(missingComponents.joined(separator: ", "))."
            )
        }

        let execution = run(executablePath: adbURL.path, arguments: ["version"])
        guard execution.exitCode == 0 else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: root,
                detail: execution.output.isEmpty
                    ? "Android Platform Tools konnten nicht ausgeführt werden."
                    : execution.output
            )
        }

        let version = androidPlatformToolsVersion(output: execution.output)
        let availability: ToolAvailability = requirement.versionConstraint.accepts(version) ? .ready : .incompatible
        let detail = availability == .ready
            ? "Bereit – Platform Tools, Command-line Tools, Build Tools, Plattform und Lizenzen erkannt."
            : incompatibleDetail(requirement: requirement, version: version)

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: version,
            path: root,
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

    private func applicationCandidate(
        applicationPath: String,
        command: String?,
        arguments: [String]?
    ) -> ToolCandidate? {
        if let command, let executable = executablePath(for: command) {
            return ToolCandidate(path: executable, executablePath: executable, versionArguments: arguments)
        }

        guard FileManager.default.fileExists(atPath: applicationPath) else { return nil }
        return ToolCandidate(path: applicationPath, executablePath: applicationPath, versionArguments: nil)
    }

    private func executableCandidate(command: String, arguments: [String]) -> ToolCandidate? {
        guard let path = executablePath(for: command) else { return nil }
        return ToolCandidate(path: path, executablePath: path, versionArguments: arguments)
    }

    private func executablePath(for command: String) -> String? {
        let environment = ProcessInfo.processInfo.environment
        let pathValue = environment["PATH"] ?? "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"

        for folder in pathValue.split(separator: ":") {
            let candidate = URL(fileURLWithPath: String(folder)).appendingPathComponent(command).path
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }

        return nil
    }

    private func run(executablePath: String, arguments: [String]) -> CommandExecution {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = (String(data: data, encoding: .utf8) ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return CommandExecution(exitCode: process.terminationStatus, output: output)
        } catch {
            return CommandExecution(exitCode: -1, output: error.localizedDescription)
        }
    }

    private func androidPlatformToolsVersion(output: String) -> SemanticVersion? {
        let versionLine = output
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first { $0.hasPrefix("Version ") }

        guard let versionLine else { return nil }
        return SemanticVersion(parsing: versionLine)
    }

    private func incompatibleDetail(
        requirement: ToolRequirement,
        version: SemanticVersion?
    ) -> String {
        guard let minimum = requirement.versionConstraint.minimum else {
            return "Die erkannte Version ist nicht kompatibel."
        }

        let actual = version?.description ?? "unbekannt"
        return "Version \(actual) erkannt. AppForge benötigt mindestens \(minimum)."
    }

    private func missingResult(requirement: ToolRequirement) -> ToolDetectionResult {
        ToolDetectionResult(
            requirement: requirement,
            availability: .missing,
            version: nil,
            path: nil,
            detail: missingDetail(for: requirement.id)
        )
    }

    private func missingDetail(for identifier: ToolIdentifier) -> String {
        switch identifier {
        case .flutter:
            "Kein gültiges Flutter SDK gefunden. Wählen Sie ein vorhandenes SDK oder einen Installationsort."
        case .xcode:
            "Xcode oder die zugehörigen Command Line Tools wurden nicht vollständig eingerichtet."
        case .androidSDK:
            "Kein vollständiges Android SDK gefunden. Android Studio kann die benötigten Komponenten verwalten."
        case .java:
            "Kein ausführbares JDK gefunden. Das mit Android Studio gelieferte JDK kann verwendet werden."
        case .git:
            "Git wurde nicht gefunden."
        case .vsCode:
            "VS Code ist optional und wurde nicht gefunden."
        case .androidStudio:
            "Android Studio ist optional und wurde nicht gefunden."
        case .xcodeGen:
            "XcodeGen ist optional und wurde nicht gefunden."
        case .supabaseCLI:
            "Supabase CLI ist optional und wurde nicht gefunden."
        case .docker:
            "Keine Docker-kompatible CLI wurde gefunden. Sie wird nur für lokale Backend-Stacks benötigt."
        }
    }
}

private struct ToolCandidate {
    let path: String
    let executablePath: String
    let versionArguments: [String]?
}

private struct CommandExecution {
    let exitCode: Int32
    let output: String
}
