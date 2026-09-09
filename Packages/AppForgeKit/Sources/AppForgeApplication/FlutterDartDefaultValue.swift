import AppForgeDomain
import Foundation

enum FlutterDartDefaultValue {
    static func expression(
        for field: FieldDefinition
    ) -> String? {
        guard let value = field.defaultValue else {
            return nil
        }

        switch value {
        case let .string(rawValue):
            return stringExpression(rawValue, dataType: field.dataType)
        case let .integer(rawValue):
            return integerExpression(rawValue, dataType: field.dataType)
        case let .decimal(rawValue):
            return decimalExpression(rawValue)
        case let .boolean(rawValue):
            return rawValue ? "true" : "false"
        case let .date(rawValue),
             let .dateTime(rawValue),
             let .time(rawValue):
            return "DateTime.parse('\(FlutterDartEscaping.singleQuoted(rawValue))')"
        case let .option(rawValue):
            return "'\(FlutterDartEscaping.singleQuoted(rawValue))'"
        }
    }

    private static func stringExpression(
        _ value: String,
        dataType: FieldDataType
    ) -> String {
        let escaped = FlutterDartEscaping.singleQuoted(value)
        switch dataType {
        case .color:
            return "DomainColorValue('\(escaped)')"
        case .location:
            return "DomainLocationValue.fromStorageString('\(escaped)')"
        default:
            return "'\(escaped)'"
        }
    }

    private static func integerExpression(
        _ value: Int,
        dataType: FieldDataType
    ) -> String {
        switch dataType {
        case .decimal, .currency, .percentage:
            "\(value).0"
        default:
            String(value)
        }
    }

    private static func decimalExpression(
        _ value: Double
    ) -> String {
        let result = String(value)
        return result.contains(".") ? result : "\(result).0"
    }
}
