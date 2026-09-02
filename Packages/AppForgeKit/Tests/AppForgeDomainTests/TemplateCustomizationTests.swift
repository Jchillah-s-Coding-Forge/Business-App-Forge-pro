import AppForgeDomain
import XCTest

final class TemplateCustomizationTests: XCTestCase {
    private let service = TemplateCustomizationService()

    func testDiffDetectsAddedRemovedAndModifiedDefinitions() {
        let baselineCustomer = makeEntity(id: "entity.customer", code: "customer", label: "Customer")
        let baselineOrder = makeEntity(id: "entity.order", code: "order", label: "Order")
        let baseline = TemplateBaselineDefinition(
            reference: TemplateReference(templateID: "inventory", version: "1.0.0"),
            entities: [baselineCustomer, baselineOrder]
        )
        var draft = makeDraft(baseline: baseline)
        draft.entities = [
            EntityDefinition(
                identity: baselineCustomer.identity.renamed(label: "Kunde")
            ),
            makeEntity(id: "entity.asset", code: "asset", label: "Asset")
        ]

        let diff = service.diff(draft)

        XCTAssertTrue(
            diff.contains(
                TemplateDiffEntry(
                    objectKind: .entity,
                    changeKind: .modified,
                    definitionID: baselineCustomer.id
                )
            )
        )
        XCTAssertTrue(
            diff.contains(
                TemplateDiffEntry(
                    objectKind: .entity,
                    changeKind: .removed,
                    definitionID: baselineOrder.id
                )
            )
        )
        XCTAssertTrue(
            diff.contains(
                TemplateDiffEntry(
                    objectKind: .entity,
                    changeKind: .added,
                    definitionID: "entity.asset"
                )
            )
        )
    }

    func testResetEntityRestoresTemplateDefaultWithoutRemovingCustomEntities() {
        let baselineCustomer = makeEntity(id: "entity.customer", code: "customer", label: "Customer")
        let baseline = TemplateBaselineDefinition(
            reference: TemplateReference(templateID: "crm", version: "1.0.0"),
            entities: [baselineCustomer]
        )
        var draft = makeDraft(baseline: baseline)
        draft.entities = [
            EntityDefinition(identity: baselineCustomer.identity.renamed(label: "Kunde")),
            makeEntity(id: "entity.custom", code: "custom", label: "Eigene Entität")
        ]

        service.resetEntity(id: baselineCustomer.id, in: &draft)

        XCTAssertEqual(
            draft.entities.first(where: { $0.id == baselineCustomer.id }),
            baselineCustomer
        )
        XCTAssertNotNil(draft.entities.first(where: { $0.id == "entity.custom" }))
    }

    func testResetFieldRestoresOnlySelectedField() {
        let name = FieldDefinition(
            identity: DefinitionIdentity(id: "field.customer.name", code: "name", label: "Name"),
            dataType: .string,
            isRequired: true
        )
        let email = FieldDefinition(
            identity: DefinitionIdentity(id: "field.customer.email", code: "email", label: "E-Mail"),
            dataType: .email
        )
        let customer = EntityDefinition(
            identity: DefinitionIdentity(id: "entity.customer", code: "customer", label: "Kunde"),
            fields: [name, email]
        )
        let baseline = TemplateBaselineDefinition(
            reference: TemplateReference(templateID: "crm", version: "1.0.0"),
            entities: [customer]
        )
        var draft = makeDraft(baseline: baseline)
        var changedName = name
        changedName.isRequired = false
        var changedEmail = email
        changedEmail.identity = changedEmail.identity.renamed(label: "Kontakt")
        draft.entities = [
            EntityDefinition(identity: customer.identity, fields: [changedName, changedEmail])
        ]

        service.resetField(entityID: customer.id, fieldID: name.id, in: &draft)

        let restored = draft.entities[0]
        XCTAssertEqual(restored.fields.first(where: { $0.id == name.id }), name)
        XCTAssertEqual(restored.fields.first(where: { $0.id == email.id }), changedEmail)
    }

    func testResetBusinessModelRestoresBaselineSnapshot() {
        let customer = makeEntity(id: "entity.customer", code: "customer", label: "Customer")
        let baseline = TemplateBaselineDefinition(
            reference: TemplateReference(templateID: "crm", version: "1.0.0"),
            entities: [customer],
            navigation: NavigationDefinition(
                items: [
                    NavigationItemDefinition(
                        id: "nav.customers",
                        label: "Customers",
                        screenID: "screen.customers"
                    )
                ]
            )
        )
        var draft = makeDraft(baseline: baseline)
        draft.entities = []
        draft.navigation = NavigationDefinition()

        service.resetBusinessModel(&draft)

        XCTAssertEqual(draft.entities, baseline.entities)
        XCTAssertEqual(draft.navigation, baseline.navigation)
        XCTAssertTrue(service.diff(draft).isEmpty)
    }

    func testDraftSnapshotIsIndependentAfterCreation() {
        let baseline = TemplateBaselineDefinition(
            reference: TemplateReference(templateID: "crm", version: "1.0.0")
        )
        var draft = makeDraft(baseline: baseline)
        let snapshot = draft.snapshot()

        draft.identity.name = "Geändert"
        draft.entities.append(makeEntity(id: "entity.customer", code: "customer", label: "Kunde"))

        XCTAssertEqual(snapshot.identity.name, "Template Test")
        XCTAssertTrue(snapshot.entities.isEmpty)
    }

    private func makeDraft(baseline: TemplateBaselineDefinition) -> ProjectSpecificationDraft {
        ProjectSpecificationDraft(
            identity: ProjectIdentity(name: "Template Test", organizationIdentifier: "de.example"),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: .supabase,
            flutterStateManagement: .riverpod,
            entities: baseline.entities,
            relations: baseline.relations,
            fieldPresentations: baseline.fieldPresentations,
            roles: baseline.roles,
            stateMachines: baseline.stateMachines,
            screens: baseline.screens,
            navigation: baseline.navigation,
            templateBaseline: baseline
        )
    }

    private func makeEntity(id: String, code: String, label: String) -> EntityDefinition {
        EntityDefinition(identity: DefinitionIdentity(id: id, code: code, label: label))
    }
}
