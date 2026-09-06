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

        requirements += optionalDeveloperRequirements
        return requirements
    }

    private var coreRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .git,
                displayName: "Git",
                purpose: "Versionsverwaltung und Repository-Initialisierung",
                isRequired: true,
                versionConstraint: .init(minimum: SupportedToolVersions.git),
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
                versionConstraint: .init(minimum: SupportedToolVersions.flutter),
                installStrategy: .userSelectedLocation
            )
        ]
    }

    private var appleRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .xcode,
                displayName: "Xcode + Command Line Tools",
                purpose: "Apple SDKs, Simulatoren, Signierung, Compiler und Builds",
                isRequired: true,
                versionConstraint: .init(minimum: SupportedToolVersions.xcode),
                installStrategy: .externalApplication
            )
        ]
    }

    private var androidRequirements: [ToolRequirement] {
        [
            ToolRequirement(
                id: .androidSDK,
                displayName: "Android SDK",
                purpose: "Platform Tools, Command-line Tools, Build Tools, Plattformen und Lizenzen",
                isRequired: true,
                versionConstraint: .init(minimum: SupportedToolVersions.androidPlatformTools),
                installStrategy: .externalApplication
            ),
            ToolRequirement(
                id: .java,
                displayName: "JDK",
                purpose: "Android Gradle Toolchain",
                isRequired: true,
                versionConstraint: .init(minimum: SupportedToolVersions.java),
                installStrategy: .externalApplication
            )
        ]
    }

    private var optionalDeveloperRequirements: [ToolRequirement] {
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
                purpose: "Optionale Android-IDE und komfortable Android-SDK-Verwaltung",
                isRequired: false,
                installStrategy: .externalApplication
            ),
            ToolRequirement(
                id: .xcodeGen,
                displayName: "XcodeGen",
                purpose: "Optionales Entwicklerwerkzeug zur reproduzierbaren Regenerierung des AppForge-Xcode-Projekts",
                isRequired: false,
                installStrategy: .manual
            ),
            ToolRequirement(
                id: .supabaseCLI,
                displayName: "Supabase CLI",
                purpose: "Optional für lokale Supabase-Entwicklung, Migrationen und Backend-Validierung",
                isRequired: false,
                installStrategy: .manual
            ),
            ToolRequirement(
                id: .docker,
                displayName: "Docker-kompatible Runtime",
                purpose: "Optional für den lokalen Supabase-Stack",
                isRequired: false,
                installStrategy: .externalApplication
            ),
            ToolRequirement(
                id: .nix,
                displayName: "Nix",
                purpose: "Optionale reproduzierbare Entwicklungsumgebung mit gepinnten Toolchains",
                isRequired: false,
                versionConstraint: .init(minimum: SupportedToolVersions.nix),
                installStrategy: .manual
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
    private let runner: any MacOSOpenCommandRunning

    public init() {
        runner = SystemMacOSOpenCommandRunner()
    }

    init(runner: any MacOSOpenCommandRunning) {
        self.runner = runner
    }

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

        try runner.run(arguments: arguments)
    }
}

enum SupportedToolVersions {
    static let git = SemanticVersion(major: 2, minor: 40)
    static let flutter = SemanticVersion(major: 3, minor: 44)
    static let xcode = SemanticVersion(major: 16, minor: 0)
    static let androidPlatformTools = SemanticVersion(major: 35, minor: 0)
    static let java = SemanticVersion(major: 17, minor: 0)
    static let nix = SemanticVersion(major: 2, minor: 4)
}
