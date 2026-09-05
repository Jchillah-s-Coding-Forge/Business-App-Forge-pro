import AppForgeDomain
import Foundation

struct VerifiedNixFlutterEnvironment: Equatable, Sendable {
    let environmentPath: String
    let receipt: NixEnvironmentReceipt
    let provenance: FlutterNixEnvironmentProvenance
}

struct NixFlutterEnvironmentVerifier: Sendable {
    private let renderer = NixFlakeRenderer()
    private let lockInspector = NixFlakeLockInspector()

    func verify(
        environmentPath: String
    ) throws -> VerifiedNixFlutterEnvironment {
        let environmentURL = URL(
            fileURLWithPath: environmentPath,
            isDirectory: true
        )
        .standardizedFileURL
        .resolvingSymlinksInPath()

        try validateDirectory(environmentURL)

        let receipt = try loadReceipt(
            environmentURL: environmentURL
        )
        guard receipt.packages.contains(.flutter) else {
            throw FlutterMaterializationError.nixEnvironmentMissingFlutter
        }

        try validateFlake(
            environmentURL: environmentURL,
            receipt: receipt
        )
        let provenance = try validateLock(
            environmentURL: environmentURL,
            receipt: receipt
        )

        return VerifiedNixFlutterEnvironment(
            environmentPath: environmentURL.path,
            receipt: receipt,
            provenance: provenance
        )
    }

    private func validateDirectory(
        _ environmentURL: URL
    ) throws {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: environmentURL.path,
            isDirectory: &isDirectory
        )
        guard exists, isDirectory.boolValue else {
            throw FlutterMaterializationError.invalidNixEnvironment
        }
    }

    private func loadReceipt(
        environmentURL: URL
    ) throws -> NixEnvironmentReceipt {
        let url = environmentURL.appendingPathComponent(
            NixEnvironmentReceipt.defaultFileName
        )

        do {
            let data = try Data(contentsOf: url)
            return try NixEnvironmentReceiptCodec().decode(data)
        } catch {
            throw FlutterMaterializationError.invalidNixEnvironment
        }
    }

    private func validateFlake(
        environmentURL: URL,
        receipt: NixEnvironmentReceipt
    ) throws {
        let plan = NixEnvironmentPlan(
            systems: receipt.systems,
            packages: receipt.packages,
            unmanagedRequirements: receipt.unmanagedRequirements
        )
        let expected = Data(renderer.render(plan).utf8)
        let actualURL = environmentURL.appendingPathComponent(
            "flake.nix"
        )

        guard let actual = try? Data(contentsOf: actualURL),
              actual == expected
        else {
            throw FlutterMaterializationError.nixEnvironmentReceiptMismatch
        }
    }

    private func validateLock(
        environmentURL: URL,
        receipt: NixEnvironmentReceipt
    ) throws -> FlutterNixEnvironmentProvenance {
        let lockURL = environmentURL.appendingPathComponent(
            "flake.lock"
        )

        let lock: NixFlakeLockProvenance
        do {
            lock = try lockInspector.inspect(
                lockFileURL: lockURL
            )
        } catch {
            throw FlutterMaterializationError.invalidNixEnvironment
        }

        guard lock.sha256 == receipt.flakeLockSHA256,
              lock.nixpkgsRevision
                  == receipt.nixpkgsLockedRevision.lowercased()
        else {
            throw FlutterMaterializationError.nixEnvironmentReceiptMismatch
        }

        return FlutterNixEnvironmentProvenance(
            nixpkgsLockedRevision: lock.nixpkgsRevision,
            flakeLockSHA256: lock.sha256
        )
    }
}
