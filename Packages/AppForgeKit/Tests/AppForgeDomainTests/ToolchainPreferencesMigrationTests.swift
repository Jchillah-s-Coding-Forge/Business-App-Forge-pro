import AppForgeDomain
import Foundation
import XCTest

final class ToolchainPreferencesMigrationTests: XCTestCase {
    func testLegacyPreferencesDecodeWithoutEnvironmentMode() throws {
        let data = Data(
            """
            {
              "flutterSDKPath": "/existing/flutter",
              "preferredIDE": "VS Code"
            }
            """.utf8
        )

        let preferences = try JSONDecoder().decode(
            ToolchainPreferences.self,
            from: data
        )

        XCTAssertEqual(
            preferences.flutterSDKPath,
            "/existing/flutter"
        )
        XCTAssertEqual(preferences.preferredIDE, .vsCode)
        XCTAssertNil(preferences.developmentEnvironmentMode)
        XCTAssertNil(preferences.nixEnvironmentPath)
        XCTAssertNil(preferences.nixExecutablePath)
    }

    func testEnvironmentModeRoundTripsWhenPresent() throws {
        let original = ToolchainPreferences(
            flutterSDKPath: nil,
            preferredIDE: .terminal,
            developmentEnvironmentMode: .nixReproducible,
            nixEnvironmentPath: "/tmp/appforge-nix",
            nixExecutablePath: "/nix/bin/nix"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(
            ToolchainPreferences.self,
            from: data
        )

        XCTAssertEqual(decoded, original)
    }
}
