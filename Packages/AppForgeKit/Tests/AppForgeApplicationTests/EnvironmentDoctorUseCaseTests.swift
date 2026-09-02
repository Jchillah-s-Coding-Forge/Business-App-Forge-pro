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
            version: SemanticVersion(major: 1, minor: 0),
            path: availability == .ready ? path : nil,
            detail: availability == .ready ? "Bereit" : "Fehlt"
        )
    }
}
