import AppForgeDomain
import Foundation

struct FlutterToolchainIdentityParser: Sendable {
    func parse(
        _ output: String
    ) throws -> FlutterToolchainIdentity {
        let dictionary = try machineVersionDictionary(output)

        guard let version = stringValue(
            in: dictionary,
            keys: ["flutterVersion", "frameworkVersion"]
        ) else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard let channel = dictionary["channel"] as? String,
              let frameworkRevision = dictionary["frameworkRevision"] as? String,
              let engineRevision = dictionary["engineRevision"] as? String,
              let dartSDKVersion = dictionary["dartSdkVersion"] as? String
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        let metadataIsValid = !version.isEmpty
            && !channel.isEmpty
            && frameworkRevision.isGitRevision
            && engineRevision.isGitRevision
            && !dartSDKVersion.isEmpty
        guard metadataIsValid else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        try validateMinimumVersion(version)

        return FlutterToolchainIdentity(
            flutterVersion: version,
            channel: channel,
            frameworkRevision: frameworkRevision,
            engineRevision: engineRevision,
            dartSDKVersion: dartSDKVersion
        )
    }

    private func machineVersionDictionary(
        _ output: String
    ) throws -> [String: Any] {
        guard let firstBrace = output.firstIndex(of: "{"),
              let lastBrace = output.lastIndex(of: "}"),
              firstBrace <= lastBrace
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }

        let json = String(output[firstBrace ... lastBrace])
        let data = Data(json.utf8)
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any]
        else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        return dictionary
    }

    private func stringValue(
        in dictionary: [String: Any],
        keys: [String]
    ) -> String? {
        keys.lazy.compactMap {
            dictionary[$0] as? String
        }.first
    }

    private func validateMinimumVersion(
        _ versionText: String
    ) throws {
        let minimum = SupportedToolVersions.flutter
        guard let version = SemanticVersion(
            parsing: versionText
        ) else {
            throw FlutterMaterializationError.invalidFlutterToolchainMetadata
        }
        guard version >= minimum else {
            throw FlutterMaterializationError.incompatibleFlutterVersion(
                actual: versionText,
                minimum: minimum.description
            )
        }
    }
}

private extension String {
    var isGitRevision: Bool {
        range(
            of: "^[0-9a-fA-F]{7,64}$",
            options: .regularExpression
        ) != nil
    }
}
