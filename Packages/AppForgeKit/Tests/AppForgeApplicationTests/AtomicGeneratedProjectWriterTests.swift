import AppForgeApplication
import AppForgeCore
import AppForgeDomain
import Foundation
import XCTest

final class AtomicGeneratedProjectWriterTests: XCTestCase {
    func testWriterCreatesNestedProjectFromValidatedPlan() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent("generated_app", isDirectory: true)
        let plan = try GenerationPlan(
            files: [
                GeneratedFile(relativePath: "lib/main.dart", contents: "void main() {}\n"),
                GeneratedFile(relativePath: "README.md", contents: "# Generated\n")
            ]
        )

        let result = try AtomicGeneratedProjectWriter().write(
            plan: plan,
            to: targetURL
        )

        XCTAssertEqual(result.standardizedFileURL, targetURL.standardizedFileURL)
        XCTAssertEqual(
            try String(
                contentsOf: targetURL.appendingPathComponent("lib/main.dart"),
                encoding: .utf8
            ),
            "void main() {}\n"
        )
        XCTAssertEqual(
            try String(
                contentsOf: targetURL.appendingPathComponent("README.md"),
                encoding: .utf8
            ),
            "# Generated\n"
        )
    }

    func testWriterRefusesToOverwriteExistingTarget() throws {
        let parentURL = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parentURL) }

        let targetURL = parentURL.appendingPathComponent("existing", isDirectory: true)
        try FileManager.default.createDirectory(
            at: targetURL,
            withIntermediateDirectories: false
        )
        let plan = try GenerationPlan(
            files: [GeneratedFile(relativePath: "README.md", contents: "new")]
        )

        XCTAssertThrowsError(
            try AtomicGeneratedProjectWriter().write(
                plan: plan,
                to: targetURL
            )
        ) { error in
            guard let appForgeError = error as? AppForgeError,
                  case .fileSystem = appForgeError
            else {
                return XCTFail("Expected fileSystem error, got \(error)")
            }
        }

        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: targetURL.appendingPathComponent("README.md").path
            )
        )
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-writer-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }
}
