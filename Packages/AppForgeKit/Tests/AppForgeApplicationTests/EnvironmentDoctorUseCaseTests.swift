import AppForgeApplication
import AppForgeDomain
import XCTest

final class EnvironmentDoctorUseCaseTests: XCTestCase {
    func testIOSAndAndroidRequireDifferentPlatformToolchains() async {
        let detector = StubToolDetector()
        let doctor = EnvironmentDoctorUseCase(detector: detector)

        let iosReport = await doctor.run(
            framework: .flutter,
            targetPlatforms: [.iOS],
            flutterSDKPath: nil
        )
        let androidReport = await doctor.run(
            framework: .flutter,
            targetPlatforms: [.android],
            flutterSDKPath: nil
        )

        XCTAssertTrue(iosReport.results.contains { $0.id == .xcode })
        XCTAssertFalse(iosReport.results.contains { $0.id == .androidSDK })
        XCTAssertFalse(iosReport.results.contains { $0.id == .java })

        XCTAssertFalse(androidReport.results.contains { $0.id == .xcode })
        XCTAssertTrue(androidReport.results.contains { $0.id == .androidSDK })
        XCTAssertTrue(androidReport.results.contains { $0.id == .java })
    }

    func testBuiltInRequiredToolsHaveExplicitMinimumVersions() {
        let requirements = ToolchainRequirements().requirements(
            for: .flutter,
            targetPlatforms: [.iOS, .android]
        )
        let required = requirements.filter(\.isRequired)

        XCTAssertFalse(required.isEmpty)
        XCTAssertTrue(required.allSatisfy { $0.versionConstraint.minimum != nil })
        XCTAssertNotNil(required.first { $0.id == .git }?.versionConstraint.minimum)
        XCTAssertNotNil(required.first { $0.id == .flutter }?.versionConstraint.minimum)
        XCTAssertNotNil(required.first { $0.id == .xcode }?.versionConstraint.minimum)
        XCTAssertNotNil(required.first { $0.id == .androidSDK }?.versionConstraint.minimum)
        XCTAssertNotNil(required.first { $0.id == .java }?.versionConstraint.minimum)
    }

    func testMissingRequiredToolMakesReportNotReady() async {
        let detector = StubToolDetector(missing: [.flutter])
        let doctor = EnvironmentDoctorUseCase(detector: detector)

        let report = await doctor.run(
            framework: .flutter,
            targetPlatforms: [.iOS],
            flutterSDKPath: "/custom/flutter"
        )

        XCTAssertFalse(report.isReady)
        XCTAssertEqual(report.requiredFailures.map(\.id), [.flutter])
    }
}

private struct StubToolDetector: ToolDetector {
    let missing: Set<ToolIdentifier>

    init(missing: Set<ToolIdentifier> = []) {
        self.missing = missing
    }

    func detect(
        requirement: ToolRequirement,
        flutterSDKPath: String?
    ) async -> ToolDetectionResult {
        let availability: ToolAvailability = missing.contains(requirement.id) ? .missing : .ready
        let path = requirement.id == .flutter ? flutterSDKPath : "/usr/bin/\(requirement.id.rawValue)"

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: SemanticVersion(major: 99, minor: 0),
            path: availability == .ready ? path : nil,
            detail: availability == .ready ? "Bereit" : "Fehlt"
        )
    }
}
