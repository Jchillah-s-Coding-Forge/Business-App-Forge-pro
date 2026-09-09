import AppForgeDomain

struct FlutterGeneratedFormRoute {
    let screen: ScreenDefinition
    let entity: EntityDefinition
    let label: String

    var propertyName: String {
        FlutterDartNaming.memberName(screen.identity.code) + "Form"
    }
}

enum FlutterGeneratedFormRoutes {
    static func make(
        specification: ProjectSpecification
    ) throws -> [FlutterGeneratedFormRoute] {
        let screens = FlutterFormRenderingSupport.formScreens(
            in: specification
        )
        let screensByID = Dictionary(
            uniqueKeysWithValues: screens.map { ($0.id, $0) }
        )
        var result: [FlutterGeneratedFormRoute] = []
        var routedScreenIDs = Set<String>()

        for item in specification.navigation.items {
            guard let screen = screensByID[item.screenID],
                  routedScreenIDs.insert(screen.id).inserted
            else {
                continue
            }
            try result.append(
                route(
                    screen: screen,
                    label: normalized(item.label, fallback: screen.identity.label),
                    specification: specification
                )
            )
        }

        for screen in screens where routedScreenIDs.insert(screen.id).inserted {
            try result.append(
                route(
                    screen: screen,
                    label: screen.identity.label,
                    specification: specification
                )
            )
        }
        return result
    }

    private static func route(
        screen: ScreenDefinition,
        label: String,
        specification: ProjectSpecification
    ) throws -> FlutterGeneratedFormRoute {
        try FlutterGeneratedFormRoute(
            screen: screen,
            entity: FlutterFormRenderingSupport.entity(
                for: screen,
                in: specification
            ),
            label: label
        )
    }

    private static func normalized(
        _ value: String,
        fallback: String
    ) -> String {
        let result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? fallback : result
    }
}
