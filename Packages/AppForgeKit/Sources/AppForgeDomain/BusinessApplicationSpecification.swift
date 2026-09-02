import Foundation

public enum BusinessPermissionAction: String, CaseIterable, Codable, Hashable, Sendable {
    case create
    case read
    case update
    case delete
    case approve
    case export
    case manage
}

public struct BusinessPermissionDefinition: Codable, Equatable, Hashable, Sendable {
    public var action: BusinessPermissionAction
    public var entityID: String?

    public init(action: BusinessPermissionAction, entityID: String? = nil) {
        self.action = action
        self.entityID = entityID
    }
}

public struct RoleDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var permissions: Set<BusinessPermissionDefinition>

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        permissions: Set<BusinessPermissionDefinition> = []
    ) {
        self.identity = identity
        self.permissions = permissions
    }
}

public struct BusinessStateDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var isInitial: Bool
    public var isTerminal: Bool

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        isInitial: Bool = false,
        isTerminal: Bool = false
    ) {
        self.identity = identity
        self.isInitial = isInitial
        self.isTerminal = isTerminal
    }
}

public indirect enum BusinessPredicate: Codable, Equatable, Sendable {
    case fieldEquals(fieldID: String, value: FieldDefaultValue)
    case fieldIsSet(fieldID: String)
    case all([BusinessPredicate])
    case any([BusinessPredicate])
    case not(BusinessPredicate)
}

public enum BusinessSideEffect: Codable, Equatable, Sendable {
    case setField(fieldID: String, value: FieldDefaultValue)
    case appendAuditEntry(message: String)
    case enqueueNotification(templateID: String)
}

public struct BusinessTransitionDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var fromStateID: String
    public var toStateID: String
    public var trigger: String
    public var allowedRoleIDs: Set<String>
    public var guards: [BusinessPredicate]
    public var sideEffects: [BusinessSideEffect]
    public var requiresAudit: Bool

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        fromStateID: String,
        toStateID: String,
        trigger: String,
        allowedRoleIDs: Set<String> = [],
        guards: [BusinessPredicate] = [],
        sideEffects: [BusinessSideEffect] = [],
        requiresAudit: Bool = false
    ) {
        self.identity = identity
        self.fromStateID = fromStateID
        self.toStateID = toStateID
        self.trigger = trigger
        self.allowedRoleIDs = allowedRoleIDs
        self.guards = guards
        self.sideEffects = sideEffects
        self.requiresAudit = requiresAudit
    }
}

public struct BusinessStateMachineDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var entityID: String
    public var stateFieldID: String
    public var states: [BusinessStateDefinition]
    public var transitions: [BusinessTransitionDefinition]

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        entityID: String,
        stateFieldID: String,
        states: [BusinessStateDefinition],
        transitions: [BusinessTransitionDefinition]
    ) {
        self.identity = identity
        self.entityID = entityID
        self.stateFieldID = stateFieldID
        self.states = states
        self.transitions = transitions
    }
}

public enum ScreenKind: String, CaseIterable, Codable, Sendable {
    case dashboard
    case list
    case detail
    case form
    case settings
    case custom
}

public struct ScreenDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var kind: ScreenKind
    public var entityID: String?
    public var visibleFieldIDs: [String]
    public var allowedRoleIDs: Set<String>

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        kind: ScreenKind,
        entityID: String? = nil,
        visibleFieldIDs: [String] = [],
        allowedRoleIDs: Set<String> = []
    ) {
        self.identity = identity
        self.kind = kind
        self.entityID = entityID
        self.visibleFieldIDs = visibleFieldIDs
        self.allowedRoleIDs = allowedRoleIDs
    }
}

public struct NavigationItemDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var label: String
    public var screenID: String
    public var iconName: String?
    public var allowedRoleIDs: Set<String>

    public init(
        id: String,
        label: String,
        screenID: String,
        iconName: String? = nil,
        allowedRoleIDs: Set<String> = []
    ) {
        self.id = id
        self.label = label
        self.screenID = screenID
        self.iconName = iconName
        self.allowedRoleIDs = allowedRoleIDs
    }
}

public struct NavigationDefinition: Codable, Equatable, Sendable {
    public var items: [NavigationItemDefinition]

    public init(items: [NavigationItemDefinition] = []) {
        self.items = items
    }
}

public enum ConflictResolutionStrategy: String, CaseIterable, Codable, Sendable {
    case latestWriteWins
    case serverWins
    case clientWins
    case manualReview
}

public struct OfflineConfiguration: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var usesLocalSingleSourceOfTruth: Bool
    public var usesSyncOutbox: Bool
    public var syncsOnReconnect: Bool
    public var conflictResolution: ConflictResolutionStrategy

    public static let businessDefault = OfflineConfiguration(
        isEnabled: true,
        usesLocalSingleSourceOfTruth: true,
        usesSyncOutbox: true,
        syncsOnReconnect: true,
        conflictResolution: .manualReview
    )

    public init(
        isEnabled: Bool,
        usesLocalSingleSourceOfTruth: Bool,
        usesSyncOutbox: Bool,
        syncsOnReconnect: Bool,
        conflictResolution: ConflictResolutionStrategy
    ) {
        self.isEnabled = isEnabled
        self.usesLocalSingleSourceOfTruth = usesLocalSingleSourceOfTruth
        self.usesSyncOutbox = usesSyncOutbox
        self.syncsOnReconnect = syncsOnReconnect
        self.conflictResolution = conflictResolution
    }
}

public struct DesignConfiguration: Codable, Equatable, Sendable {
    public var appDisplayName: String?
    public var primaryColorHex: String?
    public var logoAssetName: String?
    public var iconAssetName: String?

    public init(
        appDisplayName: String? = nil,
        primaryColorHex: String? = nil,
        logoAssetName: String? = nil,
        iconAssetName: String? = nil
    ) {
        self.appDisplayName = appDisplayName
        self.primaryColorHex = primaryColorHex
        self.logoAssetName = logoAssetName
        self.iconAssetName = iconAssetName
    }
}

public struct TemplateReference: Codable, Equatable, Sendable {
    public var templateID: String
    public var version: String

    public init(templateID: String, version: String) {
        self.templateID = templateID
        self.version = version
    }
}

public struct TemplateBaselineDefinition: Codable, Equatable, Sendable {
    public var reference: TemplateReference
    public var entities: [EntityDefinition]
    public var relations: [RelationDefinition]
    public var fieldPresentations: [FieldPresentationDefinition]
    public var roles: [RoleDefinition]
    public var stateMachines: [BusinessStateMachineDefinition]
    public var screens: [ScreenDefinition]
    public var navigation: NavigationDefinition

    public init(
        reference: TemplateReference,
        entities: [EntityDefinition] = [],
        relations: [RelationDefinition] = [],
        fieldPresentations: [FieldPresentationDefinition] = [],
        roles: [RoleDefinition] = [],
        stateMachines: [BusinessStateMachineDefinition] = [],
        screens: [ScreenDefinition] = [],
        navigation: NavigationDefinition = NavigationDefinition()
    ) {
        self.reference = reference
        self.entities = entities
        self.relations = relations
        self.fieldPresentations = fieldPresentations
        self.roles = roles
        self.stateMachines = stateMachines
        self.screens = screens
        self.navigation = navigation
    }
}
