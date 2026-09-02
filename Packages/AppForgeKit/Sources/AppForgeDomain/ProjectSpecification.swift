import Foundation

public enum OutputFramework: String, CaseIterable, Codable, Identifiable, Sendable {
    case flutter = "Flutter"
    case swiftUI = "SwiftUI"
    case compose = "Jetpack Compose"

    public var id: String {
        rawValue
    }

    public var isAvailable: Bool {
        self == .flutter
    }

    public var supportedPlatforms: Set<TargetPlatform> {
        switch self {
        case .flutter:
            [.iOS, .android]
        case .swiftUI:
            [.iOS, .macOS]
        case .compose:
            [.android]
        }
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
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var identity: ProjectIdentity
    public var framework: OutputFramework
    public var targetPlatforms: Set<TargetPlatform>
    public var backend: BackendProvider
    public var flutterStateManagement: FlutterStateManagement?
    public let architecture: ArchitectureContract
    public var entities: [EntityDefinition]
    public var relations: [RelationDefinition]
    public var fieldPresentations: [FieldPresentationDefinition]
    public var roles: [RoleDefinition]
    public var stateMachines: [BusinessStateMachineDefinition]
    public var screens: [ScreenDefinition]
    public var navigation: NavigationDefinition
    public var offline: OfflineConfiguration
    public var design: DesignConfiguration
    public var templateBaseline: TemplateBaselineDefinition?

    public var hasSupportedTargetConfiguration: Bool {
        framework.isAvailable
            && !targetPlatforms.isEmpty
            && targetPlatforms.isSubset(of: framework.supportedPlatforms)
    }

    public init(
        schemaVersion: Int = ProjectSpecification.currentSchemaVersion,
        identity: ProjectIdentity,
        framework: OutputFramework,
        targetPlatforms: Set<TargetPlatform>,
        backend: BackendProvider,
        flutterStateManagement: FlutterStateManagement?,
        architecture: ArchitectureContract = .standard,
        entities: [EntityDefinition] = [],
        relations: [RelationDefinition] = [],
        fieldPresentations: [FieldPresentationDefinition] = [],
        roles: [RoleDefinition] = [],
        stateMachines: [BusinessStateMachineDefinition] = [],
        screens: [ScreenDefinition] = [],
        navigation: NavigationDefinition = NavigationDefinition(),
        offline: OfflineConfiguration = .businessDefault,
        design: DesignConfiguration = DesignConfiguration(),
        templateBaseline: TemplateBaselineDefinition? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.identity = identity
        self.framework = framework
        self.targetPlatforms = targetPlatforms
        self.backend = backend
        self.flutterStateManagement = flutterStateManagement
        self.architecture = architecture
        self.entities = entities
        self.relations = relations
        self.fieldPresentations = fieldPresentations
        self.roles = roles
        self.stateMachines = stateMachines
        self.screens = screens
        self.navigation = navigation
        self.offline = offline
        self.design = design
        self.templateBaseline = templateBaseline
    }
}
