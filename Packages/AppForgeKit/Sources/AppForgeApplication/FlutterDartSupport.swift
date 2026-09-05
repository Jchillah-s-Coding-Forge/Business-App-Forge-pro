import AppForgeDomain
import Foundation

enum FlutterDartNaming {
    private static let reservedWords: Set<String> = [
        "abstract", "as", "assert", "async", "await", "base", "break", "case", "catch",
        "class", "const", "continue", "covariant", "default", "deferred", "do", "dynamic",
        "else", "enum", "export", "extends", "extension", "external", "factory", "false",
        "final", "finally", "for", "function", "get", "hide", "if", "implements", "import",
        "in", "interface", "is", "late", "library", "mixin", "new", "null", "of", "on",
        "operator", "part", "required", "rethrow", "return", "sealed", "set", "show",
        "static", "super", "switch", "sync", "this", "throw", "true", "try", "typedef",
        "var", "void", "when", "while", "with", "yield"
    ]

    static func packageName(from projectName: String) throws -> String {
        var value = projectName
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "_",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        if value.first?.isNumber == true {
            value = "app_\(value)"
        }
        guard !value.isEmpty else {
            throw FlutterRendererError.invalidProjectPackageName(projectName)
        }
        return value
    }

    static func snakeCase(_ code: String) -> String {
        code
            .replacingOccurrences(
                of: "([a-z0-9])([A-Z])",
                with: "$1_$2",
                options: .regularExpression
            )
            .lowercased()
    }

    static func typeName(_ code: String) -> String {
        snakeCase(code)
            .split(separator: "_")
            .map { part in
                part.prefix(1).uppercased() + part.dropFirst()
            }
            .joined()
    }

    static func memberName(_ code: String) -> String {
        let parts = snakeCase(code)
            .split(separator: "_")
            .map(String.init)
        guard let first = parts.first else {
            return code
        }

        let camelCase = first + parts.dropFirst().map { part in
            part.prefix(1).uppercased() + part.dropFirst()
        }.joined()

        return reservedWords.contains(camelCase)
            ? "\(camelCase)Value"
            : camelCase
    }

    static func dartType(for field: FieldDefinition) -> String {
        let baseType: String
        switch field.dataType {
        case .integer:
            baseType = "int"
        case .decimal, .currency, .percentage:
            baseType = "double"
        case .boolean:
            baseType = "bool"
        case .date, .dateTime, .time:
            baseType = "DateTime"
        case .string, .email, .phone, .url, .enumeration, .file, .image, .color, .location:
            baseType = "String"
        }

        return field.isRequired ? baseType : "\(baseType)?"
    }
}

enum FlutterDartEscaping {
    static func singleQuoted(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    static func yamlQuoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: """, with: "\\"")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\n", with: "\\n")
        return ""\(escaped)""
    }

    static func singleLine(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
    }
}
