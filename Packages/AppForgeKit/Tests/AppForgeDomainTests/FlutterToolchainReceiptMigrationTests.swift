import AppForgeDomain
import Foundation
import XCTest

final class FlutterToolchainReceiptMigrationTests: XCTestCase {
    func testSchemaOneReceiptWithoutExecutionFieldsStillDecodes() throws {
        let legacy = FlutterToolchainReceipt(
            schemaVersion: 1,
            flutter: FlutterToolchainIdentity(
                flutterVersion: "3.47.2",
                channel: "stable",
                frameworkRevision: String(
                    repeating: "a",
                    count: 40
                ),
                engineRevision: String(
                    repeating: "b",
                    count: 40
                ),
                dartSDKVersion: "3.11.0"
            ),
            projectPackageName: "inventory_app",
            organizationIdentifier: "de.example",
            targetPlatforms: [.android, .iOS],
            pubspecLockSHA256: String(
                repeating: "c",
                count: 64
            ),
            validatedSteps: [
                .inspectToolchain,
                .create,
                .pubGet,
                .analyze,
                .test
            ],
            executionMode: nil,
            nixEnvironment: nil
        )
        let encoded = try FlutterToolchainReceiptCodec()
            .encode(legacy)
        let legacyData = try removeExecutionKeys(
            from: encoded
        )

        let decoded = try FlutterToolchainReceiptCodec()
            .decode(legacyData)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(
            decoded.flutter.flutterVersion,
            "3.47.2"
        )
        XCTAssertNil(decoded.executionMode)
        XCTAssertNil(decoded.nixEnvironment)
    }

    func testSchemaTwoNixReceiptRoundTrips() throws {
        let original = FlutterToolchainReceipt(
            flutter: FlutterToolchainIdentity(
                flutterVersion: "3.47.2",
                channel: "stable",
                frameworkRevision: String(
                    repeating: "a",
                    count: 40
                ),
                engineRevision: String(
                    repeating: "b",
                    count: 40
                ),
                dartSDKVersion: "3.11.0"
            ),
            projectPackageName: "inventory_app",
            organizationIdentifier: "de.example",
            targetPlatforms: [.android, .iOS],
            pubspecLockSHA256: String(
                repeating: "c",
                count: 64
            ),
            validatedSteps: [
                .inspectToolchain,
                .create,
                .pubGet,
                .analyze,
                .test
            ],
            executionMode: .nixEnvironment,
            nixEnvironment: FlutterNixEnvironmentProvenance(
                nixpkgsLockedRevision: String(
                    repeating: "d",
                    count: 40
                ),
                flakeLockSHA256: String(
                    repeating: "e",
                    count: 64
                )
            )
        )

        let data = try FlutterToolchainReceiptCodec()
            .encode(original)
        let decoded = try FlutterToolchainReceiptCodec()
            .decode(data)

        XCTAssertEqual(decoded, original)
    }

    private func removeExecutionKeys(
        from data: Data
    ) throws -> Data {
        let object = try JSONSerialization.jsonObject(
            with: data
        )
        var dictionary = try XCTUnwrap(
            object as? [String: Any]
        )
        dictionary.removeValue(
            forKey: "executionMode"
        )
        dictionary.removeValue(
            forKey: "nixEnvironment"
        )
        return try JSONSerialization.data(
            withJSONObject: dictionary,
            options: [.sortedKeys]
        )
    }
}
