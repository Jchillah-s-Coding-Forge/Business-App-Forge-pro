import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class ToolchainSupportTests: XCTestCase {
    func testOptionalFailureDoesNotBlockGenerationReadiness() throws {
        let report = ToolchainReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            results: [
                result(id: .flutter, required: true, availability: .ready),
                result(id: .docker, required: false, availability: .missing)
            ]
        )

        XCTAssertTrue(report.isReady)
        XCTAssertNoThrow(try ToolchainReadinessGate().validate(report))
    }

    func testRequiredFailureBlocksGenerationReadiness() {
        let report = ToolchainReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            results: [
                result(id: .flutter, required: true, availability: .missing)
            ]
        )

        XCTAssertFalse(report.isReady)
        XCTAssertThrowsError(try ToolchainReadinessGate().validate(report))
    }

    func testJSONReportExportIsDeterministicForSameReport() throws {
        let report = ToolchainReport(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            results: [
                result(id: .git, required: true, availability: .ready),
                result(id: .supabaseCLI, required: false, availability: .missing)
            ]
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("appforge-report-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstURL = directory.appendingPathComponent("first.json")
        let secondURL = directory.appendingPathComponent("second.json")
        let exporter = JSONToolchainReportExporter()

        try exporter.export(report, to: firstURL)
        try exporter.export(report, to: secondURL)

        XCTAssertEqual(try Data(contentsOf: firstURL), try Data(contentsOf: secondURL))
    }

    func testSetupAdvisorUsesHTTPSForSupportedTools() {
        let advisor = ToolSetupAdvisor()
        let identifiers: [ToolIdentifier] = [
            .flutter,
            .xcode,
            .androidSDK,
            .java,
            .vsCode,
            .androidStudio,
            .xcodeGen,
            .supabaseCLI,
            .docker
        ]

        for identifier in identifiers {
            let recommendation = advisor.recommendation(for: identifier)
            XCTAssertNotNil(recommendation)
            XCTAssertTrue(recommendation?.urlString.hasPrefix("https://") == true)
        }
        XCTAssertNil(advisor.recommendation(for: .git))
    }

    private func result(
        id: ToolIdentifier,
        required: Bool,
        availability: ToolAvailability
    ) -> ToolDetectionResult {
        let requirement = ToolRequirement(
            id: id,
            displayName: id.rawValue,
            purpose: "Test",
            isRequired: required,
            installStrategy: .manual
        )

        return ToolDetectionResult(
            requirement: requirement,
            availability: availability,
            version: nil,
            path: nil,
            detail: availability == .ready ? "Bereit" : "Fehlt"
        )
    }
}
