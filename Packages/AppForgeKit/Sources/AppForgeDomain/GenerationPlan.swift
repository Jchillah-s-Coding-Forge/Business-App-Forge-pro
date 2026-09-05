import Foundation

public struct GeneratedFile: Equatable, Sendable {
    public let relativePath: String
    public let contents: String

    public init(relativePath: String, contents: String) {
        self.relativePath = relativePath
        self.contents = contents
    }
}

public enum GenerationPlanError: Error, Equatable, Sendable {
    case invalidRelativePath(String)
    case duplicatePath(String)
}

public struct GenerationPlan: Equatable, Sendable {
    public let files: [GeneratedFile]

    public init(files: [GeneratedFile]) throws {
        var seen = Set<String>()

        for file in files {
            guard file.relativePath.isSafeGeneratedRelativePath else {
                throw GenerationPlanError.invalidRelativePath(file.relativePath)
            }
            guard seen.insert(file.relativePath).inserted else {
                throw GenerationPlanError.duplicatePath(file.relativePath)
            }
        }

        self.files = files.sorted { lhs, rhs in
            lhs.relativePath < rhs.relativePath
        }
    }

    public func file(at relativePath: String) -> GeneratedFile? {
        files.first { $0.relativePath == relativePath }
    }
}

private extension String {
    var isSafeGeneratedRelativePath: Bool {
        guard !isEmpty,
              !hasPrefix("/"),
              !contains("\\"),
              !contains("\0")
        else {
            return false
        }

        let components = split(separator: "/", omittingEmptySubsequences: false)
        guard !components.isEmpty else {
            return false
        }

        return components.allSatisfy { component in
            let value = String(component)
            guard value != ".", value != "..", !value.isEmpty else {
                return false
            }
            return value.range(
                of: "^[A-Za-z0-9._-]+$",
                options: .regularExpression
            ) != nil
        }
    }
}
