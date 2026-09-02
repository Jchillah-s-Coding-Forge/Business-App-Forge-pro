import Foundation

public struct ProjectSpecificationDraft: Codable, Equatable, Sendable {
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

    public init(snapshot: ProjectSpecification) {
        schemaVersion = snapshot.schemaVersion
        identity = snapshot.identity
        framework = snapshot.framework
        targetPlatforms = snapshot.targetPlatforms
        backend = snapshot.backend
        flutterStateManagement = snapshot.flutterStateManagement
        architecture = snapshot.architecture
        entities = snapshot.entities
        relations = snapshot.relations
        fieldPresentations = snapshot.fieldPresentations
        roles = snapshot.roles
        stateMachines = snapshot.stateMachines
        screens = snapshot.screens
        navigation = snapshot.navigation
        offline = snapshot.offline
        design = snapshot.design
        templateBaseline = snapshot.templateBaseline
    }

    public func snapshot() -> ProjectSpecification {
        ProjectSpecification(
            schemaVersion: schemaVersion,
            identity: identity,
            framework: framework,
            targetPlatforms: targetPlatforms,
            backend: backend,
            flutterStateManagement: flutterStateManagement,
            architecture: architecture,
            entities: entities,
            relations: relations,
            fieldPresentations: fieldPresentations,
            roles: roles,
            stateMachines: stateMachines,
            screens: screens,
            navigation: navigation,
            offline: offline,
            design: design,
            templateBaseline: templateBaseline
        )
    }
}
