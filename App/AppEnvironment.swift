@MainActor
struct AppEnvironment {
    static let live = AppEnvironment()
    static let test = AppEnvironment()
}
