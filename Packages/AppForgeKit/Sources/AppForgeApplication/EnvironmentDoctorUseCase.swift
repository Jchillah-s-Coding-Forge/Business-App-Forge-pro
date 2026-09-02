import AppForgeDomain
import Foundation

public protocol ToolDetector: Sendable {
    func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult
}

public struct ToolchainRequirements: Sendable {
    public init() {}

    public func requirements(
        for framework: OutputFramework,
        targetPlatforms: Set<TargetPlatform>
    ) -> [ToolRequirement] {
        var requirements = coreRequirements

        if framework == .flutter {
            requirements += flutterRequirements
        }

        if targetPlatforms.contains(.iOS) || targetPlatforms.contains(.macOS) {
            requirements += appleRequirements
        }

        if targetPlatforms.contains(.android) {
            requirements += androidRequirements
        }

        requirements += optionalIDERequirements
        return requirements
    }

    private var coreRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .git,
                displayName: "Git",
                purpose: "Versionsverwaltung und Repository-Initialisierung",
                isRequired: true,
                installStrategy: .systemManaged
            )
        ]
    }

    private var flutterRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .flutter,
                displayName: "Flutter SDK",
                purpose: "Generierung, Analyse, Tests und Builds von Flutter-Projekten",
                isRequired: true,
                installStrategy: .userSelectedLocation
            )
        ]
    }

    private var appleRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .xcode,
                displayName: "Xcode",
                purpose: "Apple SDKs, Simulatoren, Signierung und Builds",
                isRequired: true,
                installStrategy: .externalApplication
            )
        ]
    }

    private var androidRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .androidSDK,
                displayName: "Android SDK",
                purpose: "Android Platform Tools und Builds",
                isRequired: true,
                installStrategy: .externalApplication
            ),
            ToolRequirement(
                id: .java,
                displayName: "JDK",
                purpose: "Android Gradle Toolchain",
                isRequired: true,
                installStrategy: .externalApplication
            )
        ]
    }

    private var optionalIDERequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .vsCode,
                displayName: "VS Code",
                purpose: "Optionale bevorzugte IDE und Flutter-Setup-Handoff",
                isRequired: false,
                installStrategy: .externalApplication
            ),
            ToolRequirement(
                id: .androidStudio,
                displayName: "Android Studio",
                purpose: "Optionale Android-IDE mit SDK- und Flutter-Unterstützung",
                isRequired: false,
                installStrategy: .externalApplication
            )
        ]
    }
}

public struct EnvironmentDoctorUseCase: Sendable {
    private let detector: any ToolDetector
    private let requirementsProvider: ToolchainRequirements

    public init(
        detector: any ToolDetector,
        requirementsProvider: ToolchainRequirements = ToolchainRequirements()
    ) {
        self.detector = detector
        self.requirementsProvider = requirementsProvider
    }

    public func run(
        framework: OutputFramework,
        targetPlatforms: Set<TargetPlatform>,
        flutterSDKPath: String?
    ) async -> ToolchainReport {
        let requirements = requirementsProvider.requirements(
            for: framework,
            targetPlatforms: targetPlatforms
        )
        var results: [ToolDetectionResult] = []

        for requirement in requirements {
            let result = await detector.detect(
                requirement: requirement,
                flutterSDKPath: flutterSDKPath
            )
            results.append(result)
        }

        return ToolchainReport(results: results)
    }
}

public struct SystemToolDetector: ToolDetector {
    public init() {}

    public func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        guard let candidate = candidate(for: requirement.id, flutterSDKPath: flutterSDKPath) else {
            return ToolDetectionResult(
                requirement: requirement,
                availability: .missing,
                version: nil,
                path: nil,
                detail: missingDetail(for: requirement.id)
            )
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
        let detail = availability == .ready ? "Bereit" : "Version erfüllt die Mindestanforderung nicht."

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
        case .xcode:
            executableCandidate(command: "xcodebuild", arguments: ["-version"])
        case .androidSDK:
            androidSDKCandidate()
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

    private func androidSDKCandidate() -> ToolCandidate? {
        let environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let roots = [
            environment["ANDROID_SDK_ROOT"],
            environment["ANDROID_HOME"],
            "\(home)/Library/Android/sdk"
        ].compactMap(\.self)

        for root in roots {
            let adb = URL(fileURLWithPath: root)
                .appendingPathComponent("platform-tools")
                .appendingPathComponent("adb")
                .path
            if FileManager.default.isExecutableFile(atPath: adb) {
                return ToolCandidate(path: root, executablePath: adb, versionArguments: ["version"])
            }
        }

        return nil
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

    private func missingDetail(for identifier: ToolIdentifier) -> String {
        switch identifier {
        case .flutter:
            "Kein gültiges Flutter SDK gefunden. Wählen Sie ein vorhandenes SDK oder einen Installationsort."
        case .xcode:
            "Xcode wurde nicht gefunden. Die Installation erfolgt über Apples offiziellen Weg."
        case .androidSDK:
            "Android SDK wurde nicht gefunden. Android Studio kann das SDK verwalten."
        case .java:
            "Kein ausführbares JDK gefunden. Das mit Android Studio gelieferte JDK kann verwendet werden."
        case .git:
            "Git wurde nicht gefunden."
        case .vsCode:
            "VS Code ist optional und wurde nicht gefunden."
        case .androidStudio:
            "Android Studio ist optional und wurde nicht gefunden."
        }
    }
}

public protocol ToolchainPreferenceStore {
    func load() -> ToolchainPreferences
    func save(_ preferences: ToolchainPreferences)
}

public struct UserDefaultsToolchainPreferenceStore: ToolchainPreferenceStore {
    private let key: String

    public init(key: String = "appforge.toolchain.preferences") {
        self.key = key
    }

    public func load() -> ToolchainPreferences {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let preferences = try? JSONDecoder().decode(ToolchainPreferences.self, from: data)
        else {
            return ToolchainPreferences()
        }

        return preferences
    }

    public func save(_ preferences: ToolchainPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

public protocol GeneratedProjectOpening {
    func open(projectURL: URL, preferredIDE: PreferredIDE) throws
}

public struct SystemGeneratedProjectOpener: GeneratedProjectOpening {
    public init() {}

    public func open(projectURL: URL, preferredIDE: PreferredIDE) throws {
        let arguments: [String] = switch preferredIDE {
        case .vsCode:
            ["-a", "Visual Studio Code", projectURL.path]
        case .androidStudio:
            ["-a", "Android Studio", projectURL.path]
        case .xcode:
            ["-a", "Xcode", projectURL.path]
        case .finder:
            ["-R", projectURL.path]
        case .terminal:
            ["-a", "Terminal", projectURL.path]
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = arguments
        try process.run()
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
