import Foundation

public struct ProjectSpecificationJSONCodec: Sendable {
    public init() {}

    public func encode(_ specification: ProjectSpecification) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(specification)
    }

    public func decode(_ data: Data) throws -> ProjectSpecification {
        try JSONDecoder().decode(ProjectSpecification.self, from: data)
    }
}
