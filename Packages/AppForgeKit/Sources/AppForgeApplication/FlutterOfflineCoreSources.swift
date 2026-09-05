import AppForgeDomain

struct FlutterOfflineCoreSources {
    let specification: ProjectSpecification
    let packageName: String

    func files() throws -> [GeneratedFile] {
        guard specification.offline.isEnabled else {
            return []
        }

        let storage = try FlutterOfflineStorageCoreSources(
            specification: specification,
            packageName: packageName
        ).files()
        let sync = FlutterOfflineSyncCoreSources(
            specification: specification
        ).files()

        return storage + sync
    }
}
