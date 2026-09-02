import AppForgeDomain
import XCTest

final class ToolchainTests: XCTestCase {
    func testSemanticVersionParsesToolOutput() {
        XCTAssertEqual(
            SemanticVersion(parsing: "Flutter 3.44.2 • channel stable"),
            SemanticVersion(major: 3, minor: 44, patch: 2)
        )
        XCTAssertEqual(
            SemanticVersion(parsing: "Xcode 18.0\nBuild version 16A123"),
            SemanticVersion(major: 18, minor: 0)
        )
    }

    func testMinimumVersionConstraintRejectsOlderVersion() {
        let constraint = ToolVersionConstraint(minimum: SemanticVersion(major: 3, minor: 40))

        XCTAssertTrue(constraint.accepts(SemanticVersion(major: 3, minor: 44, patch: 2)))
        XCTAssertFalse(constraint.accepts(SemanticVersion(major: 3, minor: 39, patch: 9)))
        XCTAssertFalse(constraint.accepts(nil))
    }

    func testReportOnlyBlocksOnRequiredTools() {
        let required = ToolRequirement(
            id: .flutter,
            displayName: "Flutter",
            purpose: "Generate",
            isRequired: true,
            installStrategy: .userSelectedLocation
        )
        let optional = ToolRequirement(
            id: .vsCode,
            displayName: "VS Code",
            purpose: "IDE",
            isRequired: false,
            installStrategy: .externalApplication
        )

        let report = ToolchainReport(results: [
            ToolDetectionResult(
                requirement: required,
                availability: .ready,
                version: SemanticVersion(major: 3, minor: 44, patch: 2),
                path: "/opt/flutter",
                detail: "Bereit"
            ),
            ToolDetectionResult(
                requirement: optional,
                availability: .missing,
                version: nil,
                path: nil,
                detail: "Optional"
            )
        ])

        XCTAssertTrue(report.isReady)
        XCTAssertTrue(report.requiredFailures.isEmpty)
    }
}
