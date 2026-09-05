import AppForgeDomain
import XCTest

final class FlutterOfflineRendererTests: XCTestCase {
    func testOfflineBusinessDefaultGeneratesSQLiteSSOTAndAtomicOutbox() throws {
        let specification = FlutterOfflineTestFixture.makeSpecification(
            backend: .supabase,
            offline: .businessDefault
        )
        let plan = try FlutterOfflineTestFixture.render(specification)

        try assertOfflineDependencies(plan)
        try assertSchema(plan)
        try assertAtomicMutationSource(plan)
        try assertRepositoryContract(plan)
        try assertDefaultPolicy(plan)
    }

    private func assertOfflineDependencies(
        _ plan: GenerationPlan
    ) throws {
        let pubspec = try FlutterOfflineTestFixture.contents(
            "pubspec.yaml",
            in: plan
        )
        XCTAssertTrue(pubspec.contains("sqflite: 2.4.2+1"))
        XCTAssertTrue(pubspec.contains("path: 1.9.1"))
        XCTAssertNotNil(
            plan.file(at: "lib/core/storage/app_database.dart")
        )
        XCTAssertNotNil(
            plan.file(at: "lib/core/sync/sync_outbox_repository.dart")
        )
    }

    private func assertSchema(
        _ plan: GenerationPlan
    ) throws {
        let migration = try FlutterOfflineTestFixture.contents(
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
    }

    private func assertAtomicMutationSource(
        _ plan: GenerationPlan
    ) throws {
        let local = try FlutterOfflineTestFixture.contents(
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
                "customer:$recordId:$revision:${operation.name}"
            )
        )
        XCTAssertFalse(local.contains("await db.delete("))
    }

    private func assertRepositoryContract(
        _ plan: GenerationPlan
    ) throws {
        let repository = try FlutterOfflineTestFixture.contents(
            "lib/features/customer/data/repositories/customer_repository_impl.dart",
            in: plan
        )
        XCTAssertTrue(repository.contains("implements CustomerRepository"))
        XCTAssertTrue(repository.contains("_local.fetchAll()"))
        XCTAssertTrue(
            repository.contains("_local.save(recordId: recordId, value: value)")
        )
        XCTAssertTrue(repository.contains("_local.delete(recordId)"))

        let domainRepository = try FlutterOfflineTestFixture.contents(
            "lib/features/customer/domain/repositories/customer_repository.dart",
            in: plan
        )
        XCTAssertTrue(domainRepository.contains("Future<void> save({"))
        XCTAssertTrue(
            domainRepository.contains("Future<void> delete(String recordId);")
        )
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
    }

    private func assertDefaultPolicy(
        _ plan: GenerationPlan
    ) throws {
        let policy = try FlutterOfflineTestFixture.contents(
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
        let specification = FlutterOfflineTestFixture.makeSpecification(
            backend: .localOnly,
            offline: offline
        )
        let plan = try FlutterOfflineTestFixture.render(specification)

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

        let migration = try FlutterOfflineTestFixture.contents(
            "lib/core/storage/database_migrations.dart",
            in: plan
        )
        XCTAssertFalse(migration.contains("_sync_outbox"))

        let local = try FlutterOfflineTestFixture.contents(
            "lib/features/customer/data/local/customer_local_data_source.dart",
            in: plan
        )
        XCTAssertTrue(local.contains("SyncStatus.clean.name"))
        XCTAssertTrue(local.contains("await db.delete("))
        XCTAssertFalse(local.contains("_enqueue("))
        XCTAssertFalse(local.contains("SyncOperation."))

        let policy = try FlutterOfflineTestFixture.contents(
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
        let specification = FlutterOfflineTestFixture.makeSpecification(
            backend: .supabase,
            offline: offline
        )
        let plan = try FlutterOfflineTestFixture.render(specification)

        let pubspec = try FlutterOfflineTestFixture.contents(
            "pubspec.yaml",
            in: plan
        )
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
}
