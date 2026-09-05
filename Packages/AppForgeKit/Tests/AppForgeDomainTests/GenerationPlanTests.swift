import AppForgeDomain
import XCTest

final class GenerationPlanTests: XCTestCase {
    func testPlanSortsFilesDeterministically() throws {
        let plan = try GenerationPlan(
            files: [
                GeneratedFile(relativePath: "lib/main.dart", contents: "main"),
                GeneratedFile(relativePath: "README.md", contents: "readme"),
                GeneratedFile(relativePath: "lib/app.dart", contents: "app")
            ]
        )

        XCTAssertEqual(
            plan.files.map(\.relativePath),
            ["README.md", "lib/app.dart", "lib/main.dart"]
        )
    }

    func testPlanRejectsUnsafePaths() {
        let paths = [
            "/tmp/main.dart",
            "../main.dart",
            "lib/../main.dart",
            "lib//main.dart",
            "lib\\main.dart"
        ]

        for path in paths {
            XCTAssertThrowsError(
                try GenerationPlan(
                    files: [GeneratedFile(relativePath: path, contents: "x")]
                )
            ) { error in
                XCTAssertEqual(
                    error as? GenerationPlanError,
                    .invalidRelativePath(path)
                )
            }
        }
    }

    func testPlanRejectsCaseInsensitivePathCollisions() {
        XCTAssertThrowsError(
            try GenerationPlan(
                files: [
                    GeneratedFile(relativePath: "README.md", contents: "one"),
                    GeneratedFile(relativePath: "readme.md", contents: "two")
                ]
            )
        ) { error in
            XCTAssertEqual(
                error as? GenerationPlanError,
                .duplicatePath("readme.md")
            )
        }
    }
}
