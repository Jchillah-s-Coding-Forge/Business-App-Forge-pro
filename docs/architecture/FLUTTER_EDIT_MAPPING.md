# Flutter Typed Edit Mapping

## Purpose

M3.15 closes the type boundary between the normalized values produced by a generated Flutter form and the framework-free entity required by the domain Save Use Case.

The mapper is deliberately edit-only. An edit flow already owns a complete `DomainRecord<Entity>`, so fields that are not exposed by the form can be preserved without inventing values.

```text
DomainRecord<Entity>
        +
normalized immutable form values
        ↓
<Screen>FormEditMapper.apply(...)
        ↓
new complete Entity
```

The mapper does not mutate `record.value`.

## Generated files

When at least one form screen exists, AppForge emits the shared mapping contract:

```text
lib/core/presentation/generated_form_edit_mapping.dart
```

Each form screen additionally emits a screen-specific mapper:

```text
lib/features/<feature>/presentation/mappers/<screen>_form_edit_mapper.dart
```

The mapper type is deterministic:

```text
<ScreenCodeTypeName>FormEditMapper
```

Its generated type participates in the global AppForge type-collision policy.

## Input contract

A mapper receives:

- the existing `DomainRecord<Entity>`;
- the normalized `Map<String, Object?>` emitted by the generated form runtime.

Only `ScreenDefinition.visibleFieldIDs` are read from the values map. Every visible field must have a key because the form runtime creates a normalized entry for every generated field specification.

For required fields:

```dart
GeneratedFormEditMapping.requiredValue<T>(values, fieldId)
```

requires the key to exist and the value to be a non-null value of the expected Dart type.

For optional fields:

```dart
GeneratedFormEditMapping.optionalValue<T>(values, fieldId)
```

requires the key to exist, allows `null`, and otherwise requires the expected Dart type.

## Fail-closed errors

The shared core contract distinguishes two deterministic mapping failures:

- `missingValue` — the normalized map does not contain a visible field key;
- `invalidType` — the value is not compatible with the generated Dart field type.

Both are reported through `GeneratedFormEditMappingException` with the responsible field ID.

The mapper never silently substitutes a default, coerces arbitrary strings, or falls back to the previous visible value.

## Entity reconstruction

The mapper creates a new complete entity instance.

For each entity field:

- visible field → use the normalized, type-checked form value;
- hidden field → preserve `record.value.<member>`.

For every source-side relation:

- preserve `record.value.<relation>` unchanged.

This preserves hidden required fields and source-side relationships while allowing the form to update only its declared field surface.

Named Dart constructor arguments make constructor source ordering independent of screen field order. AppForge still emits fields and relations in deterministic definition order.

## Rich values

Rich domain values are not serialized during edit mapping:

- file → `DomainFileValue`
- image → `DomainImageValue`
- color → `DomainColorValue`
- location → `DomainLocationValue`

Temporal and scalar values likewise remain their generated domain types after form normalization.

## Composition boundary

M3.15 intentionally stops before persistence.

A later composition slice may connect the pieces explicitly:

```text
GeneratedIdentifiedFormSubmit
        ↓
<Screen>FormEditMapper.apply(record, values)
        ↓
Save<Entity>(recordId, value)
```

M3.15 itself does **not**:

- instantiate a Repository;
- instantiate or call `Save<Entity>`;
- execute SQLite writes;
- create Supabase/Firebase clients;
- generate a new record ID;
- implement Create mapping;
- edit relations;
- perform navigation.

## Why Create is separate

A create flow has no existing base entity. A form may omit required hidden fields or required source-side relations, so constructing an entity would require an explicit default/value-source policy.

AppForge must not invent those values. Create mapping and record-ID generation therefore remain a separate contract.

## Determinism and runtime independence

Generated edit mapping source contains no timestamps, random IDs, host-specific paths, package-registry decisions, AppForge runtime imports, or provider-specific clients.

The same validated `ProjectSpecification`, resolved graph and lockfile must produce byte-identical edit-mapping sources.
