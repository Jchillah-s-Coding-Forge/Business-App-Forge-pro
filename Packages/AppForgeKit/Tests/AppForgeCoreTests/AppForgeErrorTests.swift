import AppForgeCore
import XCTest

final class AppForgeErrorTests: XCTestCase {
    func testUserMessageDoesNotExposeUnexpectedTechnicalDetail() {
        let error = AppForgeError.unexpected(message: "SQLite code 19")

        XCTAssertEqual(
            error.errorDescription,
            "Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es erneut."
        )
        XCTAssertEqual(error.technicalMessage, "SQLite code 19")
    }
}
