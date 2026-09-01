import Foundation

public enum AppForgeError: Error, Equatable, LocalizedError, Sendable {
    case validation(message: String)
    case configuration(message: String)
    case fileSystem(message: String)
    case generation(message: String)
    case unexpected(message: String)

    public var errorDescription: String? {
        switch self {
        case let .validation(message):
            "Die Eingaben sind noch nicht vollständig: \(message)"
        case let .configuration(message):
            "Die Projektkonfiguration ist ungültig: \(message)"
        case let .fileSystem(message):
            "Das Projekt konnte nicht gespeichert werden: \(message)"
        case let .generation(message):
            "Die Anwendung konnte nicht erzeugt werden: \(message)"
        case .unexpected:
            "Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es erneut."
        }
    }

    public var technicalMessage: String {
        switch self {
        case let .validation(message),
             let .configuration(message),
             let .fileSystem(message),
             let .generation(message),
             let .unexpected(message):
            message
        }
    }
}
