import AppForgeDomain

struct FlutterGeneratedContractValidator {
    func validate(
        _ specification: ProjectSpecification
    ) throws {
        let entities = specification.entities.sorted(by: Self.entitySort)

        try validateFeaturePaths(entities)
        try validateGeneratedTypes(
            entities,
            offlineEnabled: specification.offline.isEnabled
        )

        for entity in entities {
            try validateMembers(
                entity: entity,
                relations: specification.relations.filter {
                    $0.sourceEntityID == entity.id
                }
            )
        }
    }
}

private extension FlutterGeneratedContractValidator {
    static let reservedEntityMembers: Set<String> = [
        "copyWith",
        "fromJson",
        "hashCode",
        "noSuchMethod",
        "runtimeType",
        "toJson",
        "toString"
    ]

    static let reservedTopLevelTypes: Set<String> = [
        "App",
        "AppCubit",
        "AppDatabase",
        "DatabaseMigrations",
        "DomainColorValue",
        "DomainFileValue",
        "DomainImageValue",
        "DomainLocationValue",
        "DomainReference",
        "GeneratedFieldPresentationSchema",
        "GeneratedRelationSchema",
        "SqfliteSyncOutboxRepository",
        "SyncConflictStrategy",
        "SyncOperation",
        "SyncOutboxEntry",
        "SyncOutboxRepository",
        "SyncPolicy",
        "SyncStatus"
    ]

    func validateFeaturePaths(
        _ entities: [EntityDefinition]
    ) throws {
        var paths: [String: String] = [:]

        for entity in entities {
            let featureName = try generatedFeatureName(entity)
            let path = "lib/features/\(featureName)"
            if let firstDefinitionID = paths[path] {
                throw FlutterRendererError.generatedOutputPathCollision(
                    firstDefinitionID: firstDefinitionID,
                    secondDefinitionID: entity.id,
                    path: path
                )
            }
            paths[path] = entity.id
        }
    }

    func validateGeneratedTypes(
        _ entities: [EntityDefinition],
        offlineEnabled: Bool
    ) throws {
        var generatedTypes: [String: String] = [:]

        for entity in entities {
            let typeName = try generatedTypeName(entity)
            for generatedType in entityGeneratedTypes(
                typeName: typeName,
                offlineEnabled: offlineEnabled
            ) {
                if Self.reservedTopLevelTypes.contains(generatedType) {
                    throw FlutterRendererError.reservedGeneratedTypeName(
                        definitionID: entity.id,
                        typeName: generatedType
                    )
                }
                if let firstDefinitionID = generatedTypes[generatedType] {
                    if firstDefinitionID != entity.id {
                        throw FlutterRendererError.generatedTypeNameCollision(
                            firstDefinitionID: firstDefinitionID,
                            secondDefinitionID: entity.id,
                            typeName: generatedType
                        )
                    }
                }
                generatedTypes[generatedType] = entity.id
            }
        }
    }

    func validateMembers(
        entity: EntityDefinition,
        relations: [RelationDefinition]
    ) throws {
        let fieldMembers = entity.fields.map {
            GeneratedMember(
                definitionID: $0.id,
                code: $0.identity.code
            )
        }
        let relationMembers = relations.map {
            GeneratedMember(
                definitionID: $0.id,
                code: $0.identity.code
            )
        }
        let members = (fieldMembers + relationMembers).sorted(
            by: Self.memberSort
        )

        var generatedNames: [String: String] = [:]
        for member in members {
            let identifier = FlutterDartNaming.memberName(member.code)
            guard FlutterDartNaming.isUsableIdentifier(identifier) else {
                throw FlutterRendererError.invalidGeneratedIdentifier(
                    definitionID: member.definitionID,
                    code: member.code
                )
            }
            if Self.reservedEntityMembers.contains(identifier) {
                throw FlutterRendererError.reservedGeneratedMember(
                    definitionID: member.definitionID,
                    identifier: identifier
                )
            }
            if let firstDefinitionID = generatedNames[identifier] {
                throw FlutterRendererError.generatedMemberCollision(
                    entityID: entity.id,
                    firstDefinitionID: firstDefinitionID,
                    secondDefinitionID: member.definitionID,
                    identifier: identifier
                )
            }
            generatedNames[identifier] = member.definitionID
        }
    }

    func generatedFeatureName(
        _ entity: EntityDefinition
    ) throws -> String {
        let featureName = FlutterDartNaming.snakeCase(
            entity.identity.code
        )
        guard FlutterDartNaming.isUsableIdentifier(featureName) else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: entity.id,
                code: entity.identity.code
            )
        }
        return featureName
    }

    func generatedTypeName(
        _ entity: EntityDefinition
    ) throws -> String {
        let typeName = FlutterDartNaming.typeName(
            entity.identity.code
        )
        guard FlutterDartNaming.isUsableIdentifier(typeName) else {
            throw FlutterRendererError.invalidGeneratedIdentifier(
                definitionID: entity.id,
                code: entity.identity.code
            )
        }
        return typeName
    }

    func entityGeneratedTypes(
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

    static func memberSort(
        _ lhs: GeneratedMember,
        _ rhs: GeneratedMember
    ) -> Bool {
        let lhsName = FlutterDartNaming.memberName(lhs.code)
        let rhsName = FlutterDartNaming.memberName(rhs.code)
        if lhsName != rhsName {
            return lhsName < rhsName
        }
        return lhs.definitionID < rhs.definitionID
    }
}

private struct GeneratedMember {
    let definitionID: String
    let code: String
}
