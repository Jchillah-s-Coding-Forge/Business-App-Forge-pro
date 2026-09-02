import AppForgeDomain
import XCTest

final class BusinessModelSpecificationTests: XCTestCase {
    private let controlValidator = ControlCompatibilityValidator()
    private let specificationValidator = ProjectSpecificationValidator()

    func testBusinessRenameKeepsStableIdentity() {
        let original = DefinitionIdentity(
            id: "entity.customer",
            code: "customer",
            label: "Customer",
            singularLabel: "Customer",
            pluralLabel: "Customers"
        )

        let renamed = original.renamed(
            label: "Kunde",
            singularLabel: "Kunde",
            pluralLabel: "Kunden"
        )

        XCTAssertEqual(renamed.id, original.id)
        XCTAssertEqual(renamed.code, "customer")
        XCTAssertEqual(renamed.label, "Kunde")
        XCTAssertEqual(renamed.pluralLabel, "Kunden")
    }

    func testBooleanPresentationCanSwitchControlWithoutChangingDomainType() {
        let field = FieldDefinition(
            identity: DefinitionIdentity(id: "field.active", code: "isActive", label: "Aktiv"),
            dataType: .boolean
        )
        let checkbox = FieldPresentationDefinition(
            id: "presentation.active.checkbox",
            target: .field(field.id),
            control: .checkbox
        )
        let toggle = FieldPresentationDefinition(
            id: "presentation.active.toggle",
            target: .field(field.id),
            control: .switchToggle
        )

        XCTAssertTrue(controlValidator.validate(checkbox, field: field).isEmpty)
        XCTAssertTrue(controlValidator.validate(toggle, field: field).isEmpty)
        XCTAssertEqual(field.dataType, .boolean)
    }

    func testSliderRequiresValidNumericRange() {
        let field = FieldDefinition(
            identity: DefinitionIdentity(id: "field.progress", code: "progress", label: "Fortschritt"),
            dataType: .percentage
        )
        let invalid = FieldPresentationDefinition(
            id: "presentation.progress",
            target: .field(field.id),
            control: .slider
        )
        let valid = FieldPresentationDefinition(
            id: "presentation.progress",
            target: .field(field.id),
            control: .slider,
            numericRange: NumericRange(minimum: 0, maximum: 100)
        )

        XCTAssertEqual(
            controlValidator.validate(invalid, field: field),
            [.sliderRequiresValidRange]
        )
        XCTAssertTrue(controlValidator.validate(valid, field: field).isEmpty)
    }

    func testEnumerationRequiresOptionsBeforeSelectionControlCanBeUsed() {
        let field = FieldDefinition(
            identity: DefinitionIdentity(id: "field.status", code: "status", label: "Status"),
            dataType: .enumeration
        )
        let presentation = FieldPresentationDefinition(
            id: "presentation.status",
            target: .field(field.id),
            control: .select
        )

        XCTAssertEqual(
            controlValidator.validate(presentation, field: field),
            [.selectionOptionsRequired]
        )
    }

    func testRelationCardinalityRestrictsCompatibleControls() {
        XCTAssertEqual(
            controlValidator.compatibleControls(for: .manyToOne),
            [.select, .comboBox, .autocomplete]
        )
        XCTAssertEqual(
            controlValidator.compatibleControls(for: .manyToMany),
            [.multiSelect, .checkboxList, .chips]
        )
    }

    func testManyToManyRelationRequiresExistingJoinEntity() {
        let customer = makeEntity(id: "entity.customer", code: "customer", label: "Kunde")
        let project = makeProject(
            entities: [customer],
            relations: [
                RelationDefinition(
                    identity: DefinitionIdentity(
                        id: "relation.customer.tags",
                        code: "customerTags",
                        label: "Tags"
                    ),
                    sourceEntityID: customer.id,
                    targetEntityID: "entity.tag",
                    cardinality: .manyToMany
                )
            ]
        )

        let issues = specificationValidator.validate(project)

        XCTAssertTrue(
            issues.contains(
                .missingTargetEntity(
                    relationID: "relation.customer.tags",
                    entityID: "entity.tag"
                )
            )
        )
        XCTAssertTrue(
            issues.contains(
                .manyToManyJoinEntityRequired(relationID: "relation.customer.tags")
            )
        )
    }

    func testValidRelationalSpecificationHasNoValidationIssues() {
        let customerName = FieldDefinition(
            identity: DefinitionIdentity(id: "field.customer.name", code: "name", label: "Name"),
            dataType: .string,
            isRequired: true,
            isSearchable: true,
            isSortable: true
        )
        let customer = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.customer",
                code: "customer",
                label: "Kunde",
                pluralLabel: "Kunden"
            ),
            fields: [customerName]
        )
        let tag = makeEntity(id: "entity.tag", code: "tag", label: "Tag")
        let customerTag = makeEntity(
            id: "entity.customerTag",
            code: "customerTag",
            label: "Kunden-Tag"
        )
        let relation = RelationDefinition(
            identity: DefinitionIdentity(
                id: "relation.customer.tags",
                code: "customerTags",
                label: "Tags"
            ),
            sourceEntityID: customer.id,
            targetEntityID: tag.id,
            cardinality: .manyToMany,
            ownership: .shared,
            deleteRule: .cascade,
            joinEntityID: customerTag.id
        )
        let presentation = FieldPresentationDefinition(
            id: "presentation.customer.tags",
            target: .relation(relation.id),
            control: .chips
        )
        let project = makeProject(
            entities: [customer, tag, customerTag],
            relations: [relation],
            presentations: [presentation]
        )

        XCTAssertTrue(specificationValidator.validate(project).isEmpty)
    }

    func testInvalidDefaultAndValidationRuleAreRejected() {
        let field = FieldDefinition(
            identity: DefinitionIdentity(id: "field.quantity", code: "quantity", label: "Menge"),
            dataType: .integer,
            defaultValue: .string("zehn"),
            validationRules: [.minimumLength(1)]
        )
        let entity = EntityDefinition(
            identity: DefinitionIdentity(id: "entity.order", code: "order", label: "Auftrag"),
            fields: [field]
        )

        let issues = specificationValidator.validate(makeProject(entities: [entity]))

        XCTAssertTrue(issues.contains(.invalidDefaultValue(fieldID: field.id)))
        XCTAssertTrue(issues.contains(.invalidValidationRule(fieldID: field.id)))
    }

    private func makeProject(
        entities: [EntityDefinition] = [],
        relations: [RelationDefinition] = [],
        presentations: [FieldPresentationDefinition] = []
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(name: "Business Test", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            relations: relations,
            fieldPresentations: presentations
        )
    }

    private func makeEntity(id: String, code: String, label: String) -> EntityDefinition {
        EntityDefinition(identity: DefinitionIdentity(id: id, code: code, label: label))
    }
}
