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
        var project = makeProject(baseline: baseline)
        project.entities = [
            EntityDefinition(
                identity: baselineCustomer.identity.renamed(label: "Kunde")
            ),
            makeEntity(id: "entity.asset", code: "asset", label: "Asset")
        ]

        let diff = service.diff(project)

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
        var project = makeProject(baseline: baseline)
        project.entities = [
            EntityDefinition(identity: baselineCustomer.identity.renamed(label: "Kunde")),
            makeEntity(id: "entity.custom", code: "custom", label: "Eigene Entität")
        ]

        service.resetEntity(id: baselineCustomer.id, in: &project)

        XCTAssertEqual(
            project.entities.first(where: { $0.id == baselineCustomer.id }),
            baselineCustomer
        )
        XCTAssertNotNil(project.entities.first(where: { $0.id == "entity.custom" }))
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
        var project = makeProject(baseline: baseline)
        var changedName = name
        changedName.isRequired = false
        var changedEmail = email
        changedEmail.identity = changedEmail.identity.renamed(label: "Kontakt")
        project.entities = [
            EntityDefinition(identity: customer.identity, fields: [changedName, changedEmail])
        ]

        service.resetField(entityID: customer.id, fieldID: name.id, in: &project)

        let restored = project.entities[0]
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
        var project = makeProject(baseline: baseline)
        project.entities = []
        project.navigation = NavigationDefinition()

        service.resetBusinessModel(&project)

        XCTAssertEqual(project.entities, baseline.entities)
        XCTAssertEqual(project.navigation, baseline.navigation)
        XCTAssertTrue(service.diff(project).isEmpty)
    }

    private func makeProject(baseline: TemplateBaselineDefinition) -> ProjectSpecification {
        ProjectSpecification(
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
