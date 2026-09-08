import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterFormRendererTests: XCTestCase {
    func testFormScreenMaterializesOrderedFieldsControlsAndValidationMetadata() throws {
        let fixture = makeFormFixture()
        let plan = try render(fixture.specification)
        let path = "lib/features/asset/presentation/screens/asset_editor_form_screen.dart"
        let source = try XCTUnwrap(plan.file(at: path)?.contents)

        XCTAssertTrue(source.contains("class AssetEditorFormScreen extends StatelessWidget"))
        XCTAssertTrue(source.contains("GeneratedFormControl.comboBox"))
        XCTAssertTrue(source.contains("GeneratedFormControl.slider"))
        XCTAssertTrue(source.contains("GeneratedFormControl.segmented"))
        XCTAssertTrue(source.contains("GeneratedFormControl.datePicker"))
        XCTAssertTrue(source.contains("GeneratedFormControl.filePicker"))
        XCTAssertTrue(source.contains("GeneratedFormControl.locationPicker"))
        XCTAssertTrue(source.contains("minimumLength: 2"))
        XCTAssertTrue(source.contains("maximumLength: 80"))
        XCTAssertTrue(source.contains("minimumValue: 0.0"))
        XCTAssertTrue(source.contains("maximumValue: 200.0"))
        XCTAssertTrue(source.contains("rangeMinimum: 0.0"))
        XCTAssertTrue(source.contains("rangeMaximum: 100.0"))
        XCTAssertTrue(source.contains("value: 'active'"))
        XCTAssertTrue(source.contains("label: 'Active'"))
        XCTAssertTrue(source.contains("value: 'archived'"))
        XCTAssertTrue(source.contains("label: 'Archived'"))

        let orderedIDs = fixture.screen.visibleFieldIDs
        let offsets = try orderedIDs.map { fieldID in
            try XCTUnwrap(source.range(of: "id: '\(fieldID)'")).lowerBound
        }
        for pair in zip(offsets, offsets.dropFirst()) {
            XCTAssertLessThan(pair.0, pair.1)
        }

        XCTAssertNotNil(
            plan.file(at: "lib/core/presentation/generated_form_contract.dart")
        )
        XCTAssertNotNil(
            plan.file(at: "lib/core/presentation/generated_form_field.dart")
        )
        XCTAssertNotNil(
            plan.file(at: "lib/core/presentation/generated_entity_form_screen.dart")
        )
    }

    func testGeneratedFormBoundaryIsStandaloneAndSubmissionUsesImmutableSnapshot() throws {
        let plan = try render(makeFormFixture().specification)
        let contract = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_form_contract.dart"
            )?.contents
        )
        let screen = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_entity_form_screen.dart"
            )?.contents
        )
        let picker = try XCTUnwrap(
            plan.file(
                at: "lib/core/presentation/generated_form_picker_fields.dart"
            )?.contents
        )

        XCTAssertTrue(contract.contains("typedef GeneratedFormSubmit"))
        XCTAssertTrue(contract.contains("typedef GeneratedExternalValuePicker"))
        XCTAssertTrue(contract.contains("required GeneratedFormValueKind valueKind"))
        XCTAssertTrue(screen.contains("Map<String, Object?>.unmodifiable(normalized)"))
        XCTAssertTrue(screen.contains("await widget.onSubmit(snapshot)"))
        XCTAssertTrue(picker.contains("DomainFileValue"))
        XCTAssertTrue(picker.contains("DomainImageValue"))
        XCTAssertTrue(picker.contains("DomainColorValue"))
        XCTAssertTrue(picker.contains("DomainLocationValue"))

        let generatedFormFiles = plan.files.filter {
            $0.relativePath.contains("generated_form")
                || $0.relativePath.hasSuffix("_form_screen.dart")
        }
        for file in generatedFormFiles {
            XCTAssertFalse(file.contents.contains("package:appforge"))
            XCTAssertFalse(file.contents.contains("supabase"))
            XCTAssertFalse(file.contents.contains("firebase"))
            XCTAssertFalse(file.contents.contains("stripe"))
        }
    }

    func testMissingPresentationUsesDocumentedDeterministicDefaults() throws {
        let plan = try render(defaultControlSpecification())
        let source = try XCTUnwrap(
            plan.file(
                at: "lib/features/asset/presentation/screens/asset_form_form_screen.dart"
            )?.contents
        )

        XCTAssertTrue(source.contains("GeneratedFormControl.textField"))
        XCTAssertTrue(source.contains("GeneratedFormControl.numericField"))
        XCTAssertTrue(source.contains("GeneratedFormControl.switchToggle"))
        XCTAssertTrue(source.contains("GeneratedFormControl.datePicker"))
        XCTAssertTrue(source.contains("GeneratedFormControl.filePicker"))
        XCTAssertTrue(source.contains("GeneratedFormControl.locationPicker"))
        XCTAssertTrue(source.contains("GeneratedFormControl.select"))
    }

    func testFormRenderingIsDeterministic() throws {
        let fixture = makeFormFixture()

        XCTAssertEqual(
            try render(fixture.specification),
            try render(fixture.specification)
        )
    }
}

private extension FlutterFormRendererTests {
    struct FormFixture {
        let specification: ProjectSpecification
        let screen: ScreenDefinition
    }

    struct FixtureFields {
        let name: FieldDefinition
        let quantity: FieldDefinition
        let active: FieldDefinition
        let status: FieldDefinition
        let dueDate: FieldDefinition
        let attachment: FieldDefinition
        let location: FieldDefinition

        var all: [FieldDefinition] {
            [name, quantity, active, status, dueDate, attachment, location]
        }

        var visibleIDs: [String] {
            [
                status.id,
                name.id,
                quantity.id,
                active.id,
                dueDate.id,
                attachment.id,
                location.id
            ]
        }
    }

    func makeFormFixture() -> FormFixture {
        let fields = makeFixtureFields()
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: fields.all
        )
        let screen = formScreen(
            id: "screen.asset.editor",
            code: "asset_editor",
            entityID: asset.id,
            fields: fields.visibleIDs
        )

        return FormFixture(
            specification: specification(
                entities: [asset],
                presentations: fixturePresentations(fields),
                screens: [screen]
            ),
            screen: screen
        )
    }

    func makeFixtureFields() -> FixtureFields {
        FixtureFields(
            name: fixtureNameField(),
            quantity: fixtureQuantityField(),
            active: field(
                id: "field.asset.active",
                code: "active",
                type: .boolean
            ),
            status: fixtureStatusField(),
            dueDate: field(
                id: "field.asset.dueDate",
                code: "due_date",
                type: .date
            ),
            attachment: field(
                id: "field.asset.attachment",
                code: "attachment",
                type: .file
            ),
            location: field(
                id: "field.asset.location",
                code: "location",
                type: .location
            )
        )
    }

    func fixtureNameField() -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.asset.name",
                code: "name",
                label: "Name"
            ),
            dataType: .string,
            isRequired: true,
            validationRules: [
                .minimumLength(2),
                .maximumLength(80),
                .pattern("^[A-Za-z0-9 ]+$")
            ]
        )
    }

    func fixtureQuantityField() -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.asset.quantity",
                code: "quantity",
                label: "Quantity"
            ),
            dataType: .integer,
            isRequired: true,
            validationRules: [
                .minimumValue(0),
                .maximumValue(200)
            ]
        )
    }

    func fixtureStatusField() -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.asset.status",
                code: "status",
                label: "Status"
            ),
            dataType: .enumeration,
            options: [
                FieldOptionDefinition(
                    id: "option.active",
                    value: "active",
                    label: "Active"
                ),
                FieldOptionDefinition(
                    id: "option.archived",
                    value: "archived",
                    label: "Archived"
                )
            ]
        )
    }

    func fixturePresentations(
        _ fields: FixtureFields
    ) -> [FieldPresentationDefinition] {
        [
            presentation(
                id: "presentation.status",
                fieldID: fields.status.id,
                control: .comboBox
            ),
            presentation(
                id: "presentation.quantity",
                fieldID: fields.quantity.id,
                control: .slider,
                range: NumericRange(minimum: 0, maximum: 100)
            ),
            presentation(
                id: "presentation.active",
                fieldID: fields.active.id,
                control: .segmented
            )
        ]
    }

    func defaultControlSpecification() -> ProjectSpecification {
        let fields = defaultControlFields()
        let asset = entity(
            id: "entity.asset",
            code: "asset",
            fields: fields
        )
        let screen = formScreen(
            id: "screen.asset.form",
            code: "asset_form",
            entityID: asset.id,
            fields: fields.map(\.id)
        )
        return specification(
            entities: [asset],
            screens: [screen]
        )
    }

    func defaultControlFields() -> [FieldDefinition] {
        [
            field(id: "field.asset.name", code: "name", type: .string),
            field(id: "field.asset.quantity", code: "quantity", type: .integer),
            field(id: "field.asset.enabled", code: "enabled", type: .boolean),
            field(id: "field.asset.date", code: "date", type: .date),
            field(id: "field.asset.file", code: "file", type: .file),
            field(id: "field.asset.location", code: "location", type: .location),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.asset.status",
                    code: "status",
                    label: "Status"
                ),
                dataType: .enumeration,
                options: [
                    FieldOptionDefinition(
                        id: "option.active",
                        value: "active",
                        label: "Active"
                    )
                ]
            )
        ]
    }

    func specification(
        entities: [EntityDefinition],
        presentations: [FieldPresentationDefinition] = [],
        screens: [ScreenDefinition] = []
    ) -> ProjectSpecification {
        ProjectSpecification(
            identity: ProjectIdentity(
                name: "Form Contract",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: entities,
            fieldPresentations: presentations,
            screens: screens,
            offline: .businessDefault
        )
    }

    func entity(
        id: String,
        code: String,
        fields: [FieldDefinition] = []
    ) -> EntityDefinition {
        EntityDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            fields: fields
        )
    }

    func field(
        id: String,
        code: String,
        type: FieldDataType
    ) -> FieldDefinition {
        FieldDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            dataType: type
        )
    }

    func formScreen(
        id: String,
        code: String,
        entityID: String,
        fields: [String] = []
    ) -> ScreenDefinition {
        ScreenDefinition(
            identity: DefinitionIdentity(
                id: id,
                code: code,
                label: code
            ),
            kind: .form,
            entityID: entityID,
            visibleFieldIDs: fields
        )
    }

    func presentation(
        id: String,
        fieldID: String,
        control: FieldControl,
        range: NumericRange? = nil
    ) -> FieldPresentationDefinition {
        FieldPresentationDefinition(
            id: id,
            target: .field(fieldID),
            control: control,
            numericRange: range
        )
    }

    func render(
        _ specification: ProjectSpecification
    ) throws -> GenerationPlan {
        let graph = try FlutterOfflineTestFixture.makeGraph(
            for: specification.backend
        )
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )
        return try DeterministicFlutterProjectRenderer().makePlan(
            specification: specification,
            graph: graph,
            lockfile: lockfile
        )
    }
}
