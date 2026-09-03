import AppForgeDomain
import XCTest

final class ForgeSemanticVersionTests: XCTestCase {
    func testSemVerPrecedenceMatchesSpecificationExamples() throws {
        let versions = try [
            "1.0.0-alpha",
            "1.0.0-alpha.1",
            "1.0.0-alpha.beta",
            "1.0.0-beta",
            "1.0.0-beta.2",
            "1.0.0-beta.11",
            "1.0.0-rc.1",
            "1.0.0"
        ].map(requireVersion)

        XCTAssertEqual(versions.sorted(), versions)
    }

    func testRejectsInvalidLeadingZerosAndIdentifiers() {
        XCTAssertNil(ForgeSemanticVersion("01.0.0"))
        XCTAssertNil(ForgeSemanticVersion("1.0.0-01"))
        XCTAssertNil(ForgeSemanticVersion("1.0"))
        XCTAssertNil(ForgeSemanticVersion("1.0.0-alpha..1"))
    }

    func testBuildMetadataDoesNotChangePrecedence() throws {
        let first = try requireVersion("1.0.0+build.1")
        let second = try requireVersion("1.0.0+build.2")

        XCTAssertFalse(first < second)
        XCTAssertFalse(second < first)
        XCTAssertNotEqual(first, second)
    }

    private func requireVersion(_ value: String) throws -> ForgeSemanticVersion {
        try XCTUnwrap(ForgeSemanticVersion(value))
    }
}
