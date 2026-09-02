import Foundation

public struct DefinitionIdentity: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: String
    public var code: String
    public var label: String

    public init(id: String, code: String, label: String) {
        self.id = id
        self.code = code
        self.label = label
    }

    public func renamed(code: String? = nil, label: String? = nil) -> DefinitionIdentity {
        DefinitionIdentity(
            id: id,
            code: code ?? self.code,
            label: label ?? self.label
        )
    }
}

public enum FieldDataType: String, CaseIterable, Codable, Sendable {
    case string
    case integer
    case decimal
    case boolean
    case date
    case dateTime
    case time
    case email
    case phone
    case url
    case currency
    case percentage
    case file
    case image
    case color
}

public enum FieldDefaultValue: Codable, Equatable, Sendable {
    case string(String)
    case integer(Int)
    case decimal(Double)
    case boolean(Bool)
}

public enum FieldValidationRule: Codable, Equatable, Sendable {
    case minimumLength(Int)
    case maximumLength(Int)
    case minimumValue(Double)
    case maximumValue(Double)
    case pattern(String)
}

public struct FieldDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var dataType: FieldDataType
    public var isRequired: Bool
    public var isUnique: Bool
    public var defaultValue: FieldDefaultValue?
    public var validationRules: [FieldValidationRule]
    public var isSearchable: Bool
    public var isFilterable: Bool
    public var isSortable: Bool

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        dataType: FieldDataType,
        isRequired: Bool = false,
        isUnique: Bool = false,
        defaultValue: FieldDefaultValue? = nil,
        validationRules: [FieldValidationRule] = [],
        isSearchable: Bool = false,
        isFilterable: Bool = false,
        isSortable: Bool = false
    ) {
        self.identity = identity
        self.dataType = dataType
        self.isRequired = isRequired
        self.isUnique = isUnique
        self.defaultValue = defaultValue
        self.validationRules = validationRules
        self.isSearchable = isSearchable
        self.isFilterable = isFilterable
        self.isSortable = isSortable
    }
}

public struct EntityDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var fields: [FieldDefinition]

    public var id: String {
        identity.id
    }

    public init(identity: DefinitionIdentity, fields: [FieldDefinition] = []) {
        self.identity = identity
        self.fields = fields
    }
}

public enum RelationCardinality: String, CaseIterable, Codable, Sendable {
    case oneToOne
    case oneToMany
    case manyToOne
    case manyToMany
}

public enum RelationOwnership: String, CaseIterable, Codable, Sendable {
    case source
    case target
    case shared
}

public enum RelationDeleteRule: String, CaseIterable, Codable, Sendable {
    case restrict
    case nullify
    case cascade
}

public struct RelationDefinition: Codable, Equatable, Identifiable, Sendable {
    public var identity: DefinitionIdentity
    public var sourceEntityID: String
    public var targetEntityID: String
    public var cardinality: RelationCardinality
    public var isRequired: Bool
    public var ownership: RelationOwnership
    public var deleteRule: RelationDeleteRule
    public var joinEntityID: String?
    public var displayFieldID: String?

    public var id: String {
        identity.id
    }

    public init(
        identity: DefinitionIdentity,
        sourceEntityID: String,
        targetEntityID: String,
        cardinality: RelationCardinality,
        isRequired: Bool = false,
        ownership: RelationOwnership = .source,
        deleteRule: RelationDeleteRule = .restrict,
        joinEntityID: String? = nil,
        displayFieldID: String? = nil
    ) {
        self.identity = identity
        self.sourceEntityID = sourceEntityID
        self.targetEntityID = targetEntityID
        self.cardinality = cardinality
        self.isRequired = isRequired
        self.ownership = ownership
        self.deleteRule = deleteRule
        self.joinEntityID = joinEntityID
        self.displayFieldID = displayFieldID
    }
}

public enum FieldControl: String, CaseIterable, Codable, Hashable, Sendable {
    case textField
    case textArea
    case numericField
    case stepper
    case slider
    case checkbox
    case switchToggle
    case radioGroup
    case segmented
    case select
    case comboBox
    case autocomplete
    case multiSelect
    case checkboxList
    case chips
    case datePicker
    case timePicker
    case dateTimePicker
    case filePicker
    case imagePicker
    case colorPicker
}

public enum PresentationTarget: Codable, Equatable, Sendable {
    case field(String)
    case relation(String)
}

public struct NumericRange: Codable, Equatable, Sendable {
    public var minimum: Double
    public var maximum: Double

    public init(minimum: Double, maximum: Double) {
        self.minimum = minimum
        self.maximum = maximum
    }

    public var isValid: Bool {
        minimum < maximum
    }
}

public struct FieldPresentationDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var target: PresentationTarget
    public var control: FieldControl
    public var numericRange: NumericRange?

    public init(
        id: String,
        target: PresentationTarget,
        control: FieldControl,
        numericRange: NumericRange? = nil
    ) {
        self.id = id
        self.target = target
        self.control = control
        self.numericRange = numericRange
    }
}

public enum ControlCompatibilityIssue: Equatable, Sendable {
    case unsupportedControl(control: FieldControl)
    case sliderRequiresValidRange
}

public struct ControlCompatibilityValidator: Sendable {
    public init() {}

    public func compatibleControls(for dataType: FieldDataType) -> Set<FieldControl> {
        switch dataType {
        case .string:
            [.textField, .textArea, .select, .comboBox, .autocomplete]
        case .integer, .decimal, .currency, .percentage:
            [.numericField, .stepper, .slider]
        case .boolean:
            [.checkbox, .switchToggle, .radioGroup, .segmented]
        case .date:
            [.datePicker]
        case .dateTime:
            [.dateTimePicker]
        case .time:
            [.timePicker]
        case .email, .phone, .url:
            [.textField]
        case .file:
            [.filePicker]
        case .image:
            [.imagePicker]
        case .color:
            [.colorPicker]
        }
    }

    public func compatibleControls(for cardinality: RelationCardinality) -> Set<FieldControl> {
        switch cardinality {
        case .oneToOne, .manyToOne:
            [.select, .comboBox, .autocomplete]
        case .oneToMany, .manyToMany:
            [.multiSelect, .checkboxList, .chips]
        }
    }

    public func validate(
        _ presentation: FieldPresentationDefinition,
        field: FieldDefinition
    ) -> [ControlCompatibilityIssue] {
        validate(
            control: presentation.control,
            allowedControls: compatibleControls(for: field.dataType),
            numericRange: presentation.numericRange
        )
    }

    public func validate(
        _ presentation: FieldPresentationDefinition,
        relation: RelationDefinition
    ) -> [ControlCompatibilityIssue] {
        validate(
            control: presentation.control,
            allowedControls: compatibleControls(for: relation.cardinality),
            numericRange: presentation.numericRange
        )
    }

    private func validate(
        control: FieldControl,
        allowedControls: Set<FieldControl>,
        numericRange: NumericRange?
    ) -> [ControlCompatibilityIssue] {
        var issues: [ControlCompatibilityIssue] = []

        if !allowedControls.contains(control) {
            issues.append(.unsupportedControl(control: control))
        }

        if control == .slider, numericRange?.isValid != true {
            issues.append(.sliderRequiresValidRange)
        }

        return issues
    }
}
