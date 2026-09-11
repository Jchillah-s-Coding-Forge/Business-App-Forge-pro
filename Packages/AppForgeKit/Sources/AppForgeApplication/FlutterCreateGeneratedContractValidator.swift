import AppForgeDomain

struct FlutterCreateGeneratedContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        let routes = try FlutterGeneratedCreateRoutes.make(
            specification: specification
        )
        var generatedTypes: [String: String] = [:]

        for entity in specification.entities.sorted(by: Self.entitySort) {
            let typeName = FlutterDartNaming.typeName(entity.identity.code)
            if Self.reservedCoreTypes.contains(typeName) {
                throw FlutterRendererError.reservedGeneratedTypeName(
                    definitionID: entity.id,
                    typeName: typeName
                )
            }
            for generatedType in entityTypes(
                typeName: typeName,
                offlineEnabled: specification.offline.isEnabled
            ) {
                try registerExisting(
                    generatedType,
                    definitionID: entity.id,
                    generatedTypes: &generatedTypes
                )
            }
        }

        for screen in FlutterFormRenderingSupport.formScreens(in: specification) {
            try registerExisting(
                FlutterFormRenderingSupport.typeName(for: screen),
                definitionID: screen.id,
                generatedTypes: &generatedTypes
            )
            try registerExisting(
                FlutterFormEditMappingSupport.typeName(for: screen),
                definitionID: screen.id,
                generatedTypes: &generatedTypes
            )
        }
        for screen in FlutterListRenderingSupport.listScreens(in: specification) {
            try registerExisting(
                FlutterListRenderingSupport.typeName(for: screen),
                definitionID: screen.id,
                generatedTypes: &generatedTypes
            )
        }
        for screen in FlutterDetailRenderingSupport.detailScreens(in: specification) {
            try registerExisting(
                FlutterDetailRenderingSupport.typeName(for: screen),
                definitionID: screen.id,
                generatedTypes: &generatedTypes
            )
        }

        for route in routes {
            try registerCreateType(
                FlutterFormCreateMappingSupport.typeName(for: route.screen),
                definitionID: route.screen.id,
                generatedTypes: &generatedTypes
            )
            try registerCreateType(
                FlutterFormCreateMappingSupport.viewModelTypeName(for: route.screen),
                definitionID: route.screen.id,
                generatedTypes: &generatedTypes
            )
        }
    }
}

private extension FlutterCreateGeneratedContractValidator {
    static let reservedCoreTypes: Set<String> = [
        "AppDependencies",
        "GeneratedAppDestination",
        "GeneratedAppHome",
        "GeneratedFormCreateMapping",
        "GeneratedFormCreateMappingException",
        "GeneratedFormCreateMappingFailure",
        "RecordIdGenerator",
        "SecureUuidV4Generator"
    ]

    func registerExisting(
        _ typeName: String,
        definitionID: String,
        generatedTypes: inout [String: String]
    ) throws {
        if let firstDefinitionID = generatedTypes[typeName] {
            if firstDefinitionID != definitionID {
                throw FlutterRendererError.generatedTypeNameCollision(
                    firstDefinitionID: firstDefinitionID,
                    secondDefinitionID: definitionID,
                    typeName: typeName
                )
            }
        }
        generatedTypes[typeName] = definitionID
    }

    func registerCreateType(
        _ typeName: String,
        definitionID: String,
        generatedTypes: inout [String: String]
    ) throws {
        if Self.reservedCoreTypes.contains(typeName) {
            throw FlutterRendererError.reservedGeneratedTypeName(
                definitionID: definitionID,
                typeName: typeName
            )
        }
        try registerExisting(
            typeName,
            definitionID: definitionID,
            generatedTypes: &generatedTypes
        )
    }

    func entityTypes(
        typeName: String,
        offlineEnabled: Bool
    ) -> [String] {
        var names = [
            typeName,
            "\(typeName)Repository",
            "Get\(typeName)List",
            "Save\(typeName)",
            "Delete\(typeName)",
            "\(typeName)ViewModel"
        ]
        if offlineEnabled {
            names += [
                "\(typeName)LocalDataSource",
                "\(typeName)RepositoryImpl"
            ]
        }
        return names
    }

    static func entitySort(
        _ lhs: EntityDefinition,
        _ rhs: EntityDefinition
    ) -> Bool {
        if lhs.identity.code != rhs.identity.code {
            return lhs.identity.code < rhs.identity.code
        }
        return lhs.id < rhs.id
    }
}
