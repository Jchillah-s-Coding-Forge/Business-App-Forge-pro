import Foundation

public enum OutputFramework: String, CaseIterable, Codable, Identifiable, Sendable {
    case flutter = "Flutter"
    case swiftUI = "SwiftUI"
    case compose = "Jetpack Compose"

    public var id: String {
        rawValue
    }
}

public enum TargetPlatform: String, CaseIterable, Codable, Identifiable, Sendable {
    case iOS
    case android = "Android"
    case web = "Web"
    case macOS
    case windows = "Windows"
    case linux = "Linux"

    public var id: String {
        rawValue
    }
}

public enum FlutterStateManagement: String, CaseIterable, Codable, Identifiable, Sendable {
    case riverpod = "Riverpod"
    case blocCubit = "BLoC / Cubit"

    public var id: String {
        rawValue
    }

    public var recommendation: String {
        switch self {
        case .riverpod:
            "Empfohlen für moderne, testbare Business-Apps mit wenig Boilerplate."
        case .blocCubit:
            "Geeignet für große Teams und explizite, streng nachvollziehbare Zustände."
        }
    }
}

public enum BackendProvider: String, CaseIterable, Codable, Identifiable, Sendable {
    case localOnly = "Nur lokal"
    case supabase = "Supabase"
    case firebase = "Firebase"

    public var id: String {
        rawValue
    }

    public var guidance: String {
        switch self {
        case .localOnly:
            "Für Einzelgeräte, Prototypen und vollständig lokale Daten."
        case .supabase:
            "Empfohlen für relationale Geschäftsdaten, Rollen, Mandanten und Reporting."
        case .firebase:
            "Geeignet für Google-Infrastruktur, Realtime-Workflows und mobile Skalierung."
        }
    }
}

public struct ArchitectureContract: Codable, Equatable, Sendable {
    public static let standard = ArchitectureContract()

    public let presentationPattern: String
    public let projectStructure: String
    public let dataAccess: String
    public let businessLogic: String
    public let localDataPolicy: String
    public let principles: [String]

    private init() {
        presentationPattern = "MVVM"
        projectStructure = "Feature-First"
        dataAccess = "Repository Pattern"
        businessLogic = "Use Cases"
        localDataPolicy = "Single Source of Truth"
        principles = ["Clean Code", "KISS", "DRY", "SOLID"]
    }
}

public struct ProjectIdentity: Codable, Equatable, Sendable {
    public var name: String
    public var organizationIdentifier: String

    public init(name: String, organizationIdentifier: String) {
        self.name = name
        self.organizationIdentifier = organizationIdentifier
    }
}

public struct ProjectSpecification: Codable, Equatable, Sendable {
    public var identity: ProjectIdentity
    public var framework: OutputFramework
    public var targetPlatforms: Set<TargetPlatform>
    public var backend: BackendProvider
    public var flutterStateManagement: FlutterStateManagement?
    public let architecture: ArchitectureContract

    public init(
        identity: ProjectIdentity,
        framework: OutputFramework,
        targetPlatforms: Set<TargetPlatform>,
        backend: BackendProvider,
        flutterStateManagement: FlutterStateManagement?,
        architecture: ArchitectureContract = .standard
    ) {
        self.identity = identity
        self.framework = framework
        self.targetPlatforms = targetPlatforms
        self.backend = backend
        self.flutterStateManagement = flutterStateManagement
        self.architecture = architecture
    }
}
