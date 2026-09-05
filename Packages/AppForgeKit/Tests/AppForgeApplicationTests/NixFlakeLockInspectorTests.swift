@testable import AppForgeApplication
import AppForgeDomain
import Foundation
import XCTest

final class NixFlakeLockInspectorTests: XCTestCase {
    func testInspectorExtractsRevisionAndStableSHA256() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let lockURL = directory.appendingPathComponent("flake.lock")
        try validLock().write(
            to: lockURL,
            atomically: true,
            encoding: .utf8
        )

        let first = try NixFlakeLockInspector().inspect(
            lockFileURL: lockURL
        )
        let second = try NixFlakeLockInspector().inspect(
            lockFileURL: lockURL
        )

        XCTAssertEqual(first, second)
        XCTAssertEqual(
            first.nixpkgsRevision,
            String(repeating: "b", count: 40)
        )
        XCTAssertEqual(first.sha256.count, 64)
    }

    func testInspectorRejectsLockWithoutPinnedNixpkgsRevision() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let lockURL = directory.appendingPathComponent("flake.lock")
        let invalid = """
        {
          "nodes": {
            "nixpkgs": {
              "locked": {
                "type": "github"
              }
            },
            "root": {
              "inputs": {
                "nixpkgs": "nixpkgs"
              }
            }
          },
          "root": "root",
          "version": 7
        }
        """
        try invalid.write(
            to: lockURL,
            atomically: true,
            encoding: .utf8
        )

        XCTAssertThrowsError(
            try NixFlakeLockInspector().inspect(
                lockFileURL: lockURL
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .missingLockedNixpkgsRevision
            )
        }
    }

    func testInspectorRejectsMissingLockFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        XCTAssertThrowsError(
            try NixFlakeLockInspector().inspect(
                lockFileURL: directory.appendingPathComponent(
                    "flake.lock"
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? NixEnvironmentError,
                .invalidFlakeLock
            )
        }
    }

    private func validLock() -> String {
        let revision = String(repeating: "b", count: 40)
        return """
        {
          "nodes": {
            "nixpkgs": {
              "locked": {
                "owner": "NixOS",
                "repo": "nixpkgs",
                "rev": "\(revision)",
                "type": "github"
              }
            },
            "root": {
              "inputs": {
                "nixpkgs": "nixpkgs"
              }
            }
          },
          "root": "root",
          "version": 7
        }
        """
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(
            "appforge-nix-lock-tests-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: false
        )
        return url
    }
}
