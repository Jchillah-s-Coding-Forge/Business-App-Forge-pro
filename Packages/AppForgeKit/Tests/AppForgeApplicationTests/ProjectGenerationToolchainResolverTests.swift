import AppForgeApplication
import AppForgeDomain
import XCTest

final class ProjectGenerationToolchainResolverTests: XCTestCase {
    private let resolver = ResolveProjectGenerationToolchainUseCase()

    func testManagedModeRequiresExplicitFlutterSDK() throws {
        let toolchain = try resolver(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/opt/flutter",
                developmentEnvironmentMode: .appForgeManaged
            )
        )

        XCTAssertEqual(
            toolchain,
            .directSDK(path: "/opt/flutter")
        )
    }

    func testExistingToolchainRequiresExplicitFlutterSDK() throws {
        let toolchain = try resolver(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/Users/test/flutter",
                developmentEnvironmentMode: .existingToolchain
            )
        )

        XCTAssertEqual(
            toolchain,
            .directSDK(path: "/Users/test/flutter")
        )
    }

    func testNixModeUsesOnlyStoredNixEnvironmentAndExecutable() throws {
        let toolchain = try resolver(
            preferences: ToolchainPreferences(
                flutterSDKPath: "/must/not/be/used",
                developmentEnvironmentMode: .nixReproducible,
                nixEnvironmentPath: "/tmp/appforge-nix",
                nixExecutablePath: "/nix/bin/nix"
            )
        )

        XCTAssertEqual(
            toolchain,
            .nixEnvironment(
                environmentPath: "/tmp/appforge-nix",
                nixExecutablePath: "/nix/bin/nix"
            )
        )
    }

    func testManagedModeNeverFallsBackToNix() {
        XCTAssertThrowsError(
            try resolver(
                preferences: ToolchainPreferences(
                    developmentEnvironmentMode: .appForgeManaged,
                    nixEnvironmentPath: "/tmp/appforge-nix",
                    nixExecutablePath: "/nix/bin/nix"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? ProjectGenerationToolchainError,
                .missingFlutterSDK(.appForgeManaged)
            )
        }
    }

    func testNixModeNeverFallsBackToFlutterSDK() {
        XCTAssertThrowsError(
            try resolver(
                preferences: ToolchainPreferences(
                    flutterSDKPath: "/opt/flutter",
                    developmentEnvironmentMode: .nixReproducible
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? ProjectGenerationToolchainError,
                .missingNixEnvironment
            )
        }
    }

    func testNixExecutableMustBeAbsolute() {
        XCTAssertThrowsError(
            try resolver(
                preferences: ToolchainPreferences(
                    developmentEnvironmentMode: .nixReproducible,
                    nixEnvironmentPath: "/tmp/appforge-nix",
                    nixExecutablePath: "nix"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? ProjectGenerationToolchainError,
                .invalidNixExecutablePath
            )
        }
    }

    func testNixEnvironmentMustBeAbsolute() {
        XCTAssertThrowsError(
            try resolver(
                preferences: ToolchainPreferences(
                    developmentEnvironmentMode: .nixReproducible,
                    nixEnvironmentPath: "relative/environment",
                    nixExecutablePath: "/nix/bin/nix"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? ProjectGenerationToolchainError,
                .invalidNixEnvironmentPath
            )
        }
    }
}
