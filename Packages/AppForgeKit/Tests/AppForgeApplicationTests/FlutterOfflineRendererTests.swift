import AppForgeApplication
import AppForgeDomain
import XCTest

final class FlutterOfflineRendererTests: XCTestCase {
    func testOfflineBusinessDefaultGeneratesSQLiteSSOTAndAtomicOutbox() throws {
        let specification = makeSpecification(
            backend: .supabase,
            offline: .businessDefault
        )
        let plan = try render(specification)

        let pubspec = try contents("pubspec.yaml", in: plan)
        XCTAssertTrue(pubspec.contains("sqflite: 2.4.2+1"))
        XCTAssertTrue(pubspec.contains("path: 1.9.1"))

        XCTAssertNotNil(
            plan.file(at: "lib/core/storage/app_database.dart")
        )
        XCTAssertNotNil(
            plan.file(at: "lib/core/sync/sync_outbox_repository.dart")
        )

        let migration = try contents(
            "lib/core/storage/database_migrations.dart",
            in: plan
        )
        XCTAssertTrue(
            migration.contains("CREATE TABLE IF NOT EXISTS \\\"_sync_outbox\\\"")
        )
        XCTAssertTrue(
            migration.contains("CREATE TABLE IF NOT EXISTS \\\"customer\\\"")
        )
        XCTAssertTrue(migration.contains("\\\"_record_id\\\" TEXT PRIMARY KEY"))
        XCTAssertTrue(migration.contains("\\\"_sync_revision\\\" INTEGER"))
        XCTAssertTrue(migration.contains("\\\"_sync_status\\\" TEXT NOT NULL"))
        XCTAssertTrue(migration.contains("\\\"price\\\" REAL"))
        XCTAssertTrue(migration.contains("\\\"active\\\" INTEGER"))
        XCTAssertTrue(migration.contains("\\\"scheduled_at\\\" TEXT"))

        let local = try contents(
            "lib/features/customer/data/local/customer_local_data_source.dart",
            in: plan
        )
        XCTAssertTrue(local.contains("await db.transaction((txn) async"))
        XCTAssertTrue(local.contains("await txn.insert("))
        XCTAssertTrue(local.contains("await _enqueue("))
        XCTAssertTrue(local.contains("SyncOperation.create"))
        XCTAssertTrue(local.contains("SyncOperation.update"))
        XCTAssertTrue(local.contains("SyncOperation.delete"))
        XCTAssertTrue(local.contains("'_deleted_at': now"))
        XCTAssertTrue(local.contains("'_sync_status': SyncStatus.deleted.name"))
        XCTAssertTrue(
            local.contains(
                "customer:$recordId:$revision:\${operation.name}"
            )
        )
        XCTAssertFalse(
            local.contains("await db.delete(")
        )

        let repository = try contents(
            "lib/features/customer/data/repositories/customer_repository_impl.dart",
            in: plan
        )
        XCTAssertTrue(repository.contains("implements CustomerRepository"))
        XCTAssertTrue(repository.contains("_local.fetchAll()"))
        XCTAssertTrue(
            repository.contains("_local.save(recordId: recordId, value: value)")
        )
        XCTAssertTrue(repository.contains("_local.delete(recordId)"))

        let domainRepository = try contents(
            "lib/features/customer/domain/repositories/customer_repository.dart",
            in: plan
        )
        XCTAssertTrue(domainRepository.contains("Future<void> save({"))
        XCTAssertTrue(domainRepository.contains("Future<void> delete(String recordId);"))
        XCTAssertNotNil(
            plan.file(
                at: "lib/features/customer/domain/use_cases/save_customer.dart"
            )
        )
        XCTAssertNotNil(
            plan.file(
                at: "lib/features/customer/domain/use_cases/delete_customer.dart"
            )
        )

        let policy = try contents(
            "lib/core/sync/sync_policy.dart",
            in: plan
        )
        XCTAssertTrue(
            policy.contains("SyncConflictStrategy.manualReview")
        )
        XCTAssertTrue(policy.contains("syncsOnReconnect: true"))
    }

    func testOfflineLocalOnlyWithoutOutboxUsesHardDeleteAndNoOutboxFiles() throws {
        let offline = OfflineConfiguration(
            isEnabled: true,
            usesLocalSingleSourceOfTruth: true,
            usesSyncOutbox: false,
            syncsOnReconnect: false,
            conflictResolution: .clientWins
        )
        let specification = makeSpecification(
            backend: .localOnly,
            offline: offline
        )
        let plan = try render(specification)

        XCTAssertNotNil(
            plan.file(at: "lib/core/storage/app_database.dart")
        )
        XCTAssertNil(
            plan.file(at: "lib/core/sync/sync_operation.dart")
        )
        XCTAssertNil(
            plan.file(at: "lib/core/sync/sync_outbox_entry.dart")
        )
        XCTAssertNil(
            plan.file(at: "lib/core/sync/sync_outbox_repository.dart")
        )

        let migration = try contents(
            "lib/core/storage/database_migrations.dart",
            in: plan
        )
        XCTAssertFalse(migration.contains("_sync_outbox"))

        let local = try contents(
            "lib/features/customer/data/local/customer_local_data_source.dart",
            in: plan
        )
        XCTAssertTrue(local.contains("SyncStatus.clean.name"))
        XCTAssertTrue(local.contains("await db.delete("))
        XCTAssertFalse(local.contains("_enqueue("))
        XCTAssertFalse(local.contains("SyncOperation."))

        let policy = try contents(
            "lib/core/sync/sync_policy.dart",
            in: plan
        )
        XCTAssertTrue(policy.contains("SyncConflictStrategy.clientWins"))
        XCTAssertTrue(policy.contains("syncsOnReconnect: false"))
    }

    func testOfflineDisabledDoesNotGenerateSQLiteOrSyncLayer() throws {
        let offline = OfflineConfiguration(
            isEnabled: false,
            usesLocalSingleSourceOfTruth: false,
            usesSyncOutbox: false,
            syncsOnReconnect: false,
            conflictResolution: .manualReview
        )
        let specification = makeSpecification(
            backend: .supabase,
            offline: offline
        )
        let plan = try render(specification)

        let pubspec = try contents("pubspec.yaml", in: plan)
        XCTAssertFalse(pubspec.contains("sqflite:"))
        XCTAssertFalse(pubspec.contains("path: 1.9.1"))
        XCTAssertNil(
            plan.file(at: "lib/core/storage/app_database.dart")
        )
        XCTAssertNil(
            plan.file(
                at: "lib/features/customer/data/local/customer_local_data_source.dart"
            )
        )
        XCTAssertNil(
            plan.file(
                at: "lib/features/customer/data/repositories/customer_repository_impl.dart"
            )
        )
    }

    func testOfflineRendererRejectsReservedSystemColumnCode() throws {
        let reservedField = FieldDefinition(
            identity: DefinitionIdentity(
                id: "field.customer.system",
                code: "_sync_status",
                label: "System Status"
            ),
            dataType: .string
        )
        let specification = makeSpecification(
            backend: .supabase,
            offline: .businessDefault,
            additionalFields: [reservedField]
        )
        let graph = try makeGraph(for: specification.backend)
        let lockfile = ForgeLockfileBuilder().build(
            graph: graph,
            specification: specification
        )

        XCTAssertThrowsError(
            try DeterministicFlutterProjectRenderer().makePlan(
                specification: specification,
                graph: graph,
                lockfile: lockfile
            )
        ) { error in
            XCTAssertEqual(
                error as? FlutterRendererError,
                .reservedGeneratedStorageIdentifier(
                    definitionID: reservedField.id,
                    identifier: "_sync_status"
                )
            )
        }
    }

    func testOfflineRenderingRemainsDeterministic() throws {
        let specification = makeSpecification(
            backend: .supabase,
            offline: .businessDefault
        )
        let first = try render(specification)
        let second = try render(specification)

        XCTAssertEqual(first, second)
        XCTAssertEqual(
            first.files.map(\.relativePath),
            second.files.map(\.relativePath)
        )
    }

    private func render(
        _ specification: ProjectSpecification
    ) throws -> GenerationPlan {
        let graph = try makeGraph(for: specification.backend)
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

    private func contents(
        _ path: String,
        in plan: GenerationPlan
    ) throws -> String {
        try XCTUnwrap(plan.file(at: path)?.contents)
    }

    private func makeSpecification(
        backend: BackendProvider,
        offline: OfflineConfiguration,
        additionalFields: [FieldDefinition] = []
    ) -> ProjectSpecification {
        let fields = [
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.name",
                    code: "name",
                    label: "Name"
                ),
                dataType: .string,
                isRequired: true
            ),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.price",
                    code: "price",
                    label: "Price"
                ),
                dataType: .currency
            ),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.active",
                    code: "active",
                    label: "Active"
                ),
                dataType: .boolean,
                isRequired: true
            ),
            FieldDefinition(
                identity: DefinitionIdentity(
                    id: "field.customer.scheduledAt",
                    code: "scheduledAt",
                    label: "Scheduled At"
                ),
                dataType: .dateTime
            )
        ] + additionalFields

        let customer = EntityDefinition(
            identity: DefinitionIdentity(
                id: "entity.customer",
                code: "customer",
                label: "Customer"
            ),
            fields: fields
        )

        return ProjectSpecification(
            identity: ProjectIdentity(
                name: "Offline Business",
                organizationIdentifier: "de.example"
            ),
            framework: .flutter,
            targetPlatforms: [.iOS, .android],
            backend: backend,
            flutterStateManagement: .riverpod,
            entities: [customer],
            offline: offline
        )
    }

    private func makeGraph(
        for backend: BackendProvider
    ) throws -> ResolvedProductGraph {
        let version = try XCTUnwrap(ForgeSemanticVersion("1.0.0"))
        let contract = ForgePackageContract(
            id: "foundation.core",
            version: version,
            kind: .foundation,
            supportedFrameworks: [.flutter],
            supportedBackends: [backend],
            maturity: .stable,
            source: .bundled
        )
        return ResolvedProductGraph(
            packages: [ResolvedPackage(contract: contract)],
            capabilities: []
        )
    }
}
