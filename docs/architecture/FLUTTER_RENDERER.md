# Flutter Renderer

## Purpose

The Flutter renderer turns an already validated and resolved AppForge product into normal editable Flutter source code.

The renderer sits after package resolution:

```text
ProjectSpecification
        +
package requests
        ↓
ResolveProductPackagesUseCase
        ↓
ResolvedProductGraph + forge.lock
        ↓
DeterministicFlutterProjectRenderer
        ↓
GenerationPlan
        ↓
AtomicGeneratedProjectWriter
        ↓
standalone Flutter source tree
```

It never queries a package registry, chooses package versions, downloads source archives, executes install hooks, or applies template-specific post-generation rewrites.

## GenerationPlan

`GenerationPlan` is the immutable boundary between rendering and filesystem mutation.

Every `GeneratedFile` contains:

- a relative POSIX path
- UTF-8 text content

The plan rejects:

- absolute paths
- `..` traversal
- `.` path components
- empty path components
- backslash paths
- unsupported path characters
- exact or case-insensitive duplicate paths

Files are sorted by path before the plan is exposed. The same rendered inputs therefore produce the same ordered plan independently of dictionary iteration order.

## Renderer validation

`DeterministicFlutterProjectRenderer` requires:

- `OutputFramework.flutter`
- a valid `ProjectSpecification`
- a `ForgeLockfile` that exactly matches the supplied `ResolvedProductGraph` and specification

The lockfile is rebuilt from the graph for comparison before rendering. A stale or substituted lockfile fails closed.

The renderer does not repair invalid input.

## Generated core files

M3.2 generates deterministic AppForge-owned project files including:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/app.dart`
- `forge.lock`
- `appforge.generated.json`
- `README.md`
- `.gitignore`
- a Flutter widget smoke test

`main.dart` and `app.dart` remain separate by contract.

## State management

The project specification controls the generated bootstrap.

Riverpod projects use a root `ProviderScope`.

BLoC / Cubit projects generate a minimal `AppCubit` and root `BlocProvider`.

Dependency versions are selected to remain compatible with the currently supported AppForge Flutter/Dart baseline instead of blindly selecting the newest package release.

## Feature-First domain generation

Every `EntityDefinition` produces a deterministic feature slice:

```text
lib/features/<feature>/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── use_cases/
└── presentation/
    └── view_models/
```

The renderer generates:

- framework-free Dart entities
- provider-neutral rich domain value objects
- source-side relationship references
- repository interfaces
- list/save/delete use cases
- plain view-model boundaries
- deterministic relation and field-presentation metadata

Offline-first projects additionally materialize SQLite storage and outbox mappings. Supabase/Firebase adapters, provider foreign keys/RLS, file uploads, image processing, and maps/geocoding remain later renderer/backend slices.

DTOs and backend implementation details must remain outside the domain layer.

## Field mapping

Current deterministic field mapping:

| Project field | Dart type |
| --- | --- |
| string, email, phone, URL | `String` |
| enumeration | `String` |
| file | `DomainFileValue` |
| image | `DomainImageValue` |
| color | `DomainColorValue` |
| location | `DomainLocationValue` |
| integer | `int` |
| decimal, currency, percentage | `double` |
| boolean | `bool` |
| date, dateTime, time | `DateTime` |

Required fields are non-nullable and constructor-required. Optional fields are nullable.

Rich values remain framework- and provider-neutral:

- file/image values validate and retain URI references;
- colors normalize and validate `#RRGGBB` / `#RRGGBBAA`;
- locations validate finite latitude/longitude values and geographic ranges;
- offline SQLite storage uses deterministic string representations and reconstructs the value objects when reading.

Generated repository reads return provider-neutral `DomainRecord<T>` values. A record carries the stable technical `recordId` alongside the framework-free entity value, so list/detail/edit/delete flows can address the same persisted row without leaking SQLite metadata into the entity itself. Empty record IDs fail closed.

Source-side relations are materialized as `DomainReference(entityId, recordId)`. One-to-one and many-to-one relations are single references; one-to-many and many-to-many relations are defensively unmodifiable lists. Offline storage persists to-one record IDs as text and to-many record IDs as deterministic JSON arrays. This slice intentionally does not imply provider foreign keys or RLS.

`FieldPresentationDefinition` and relation metadata are emitted as standalone generated schema metadata so later form/screen renderers can consume the original product intent without an AppForge runtime dependency.

Dart reserved member names are mapped deterministically rather than emitted as invalid source.

## Generated form screens

M3.9 materializes validated `ScreenDefinition(kind: .form)` entries as normal Flutter source. The screen contract remains build-time-only: generated forms import Flutter and generated project sources, never an AppForge runtime.

The deterministic pipeline is:

```text
ScreenDefinition.form
  -> ordered visibleFieldIDs
  -> explicit FieldPresentationDefinition or documented default control
  -> GeneratedFormFieldSpec
  -> reusable Material control
  -> immutable submit snapshot
```

`visibleFieldIDs` is authoritative for both field inclusion and field order. Relation presentations are intentionally not injected into form screens because the current screen model can position field IDs only. Relation metadata remains available in `domain_schema.dart` for a later explicit screen-contract extension.

When a visible field has no explicit presentation, the Flutter renderer uses this stable default map:

| Field type | Default control |
| --- | --- |
| string, email, phone, URL | `textField` |
| integer, decimal, currency, percentage | `numericField` |
| boolean | `switchToggle` |
| date | `datePicker` |
| dateTime | `dateTimePicker` |
| time | `timePicker` |
| enumeration | `select` |
| file | `filePicker` |
| image | `imagePicker` |
| color | `colorPicker` |
| location | `locationPicker` |

Explicit compatible presentations remain authoritative. A visible field with multiple presentations fails closed rather than choosing one by array order.

Generated `GeneratedFormFieldSpec` values retain required-state, enumeration options, string length/pattern validation, numeric minimum/maximum validation, and slider range metadata. Date/time controls use Flutter Material pickers. File, image, color, and location controls use a provider-neutral `GeneratedExternalValuePicker` callback so generated UI does not assume Supabase Storage, Firebase Storage, maps, or geocoding.

The domain type for location is `DomainLocationValue`. Although the broader product model also permits text/autocomplete location presentations for future address/geocoding experiences, M3.9 cannot materialize those controls without changing the value contract. The Flutter form renderer therefore fails closed for visible `location + textField/autocomplete` combinations and requires `locationPicker` in this slice.

Submission is deliberately infrastructure-neutral. `GeneratedEntityFormScreen` normalizes visible field values, creates an unmodifiable `Map<String, Object?>` snapshot, and passes it to an injected async submit callback. Repository, Supabase, Firebase, Stripe, routing, and workflow transitions remain outside this screen slice.

Form screen paths and generated widget types participate in the same pre-render collision policy as entity/repository/use-case/view-model output. No silent suffixing or renaming is allowed.

## Generated contract collision validation

Before any source file is rendered, AppForge validates the complete generated Dart contract.

The validator rejects:

- different entity codes that normalize to the same `lib/features/<feature>` path;
- field/relation members that normalize to the same Dart member name;
- members reserved for generated or Dart object contracts such as `copyWith`, `toJson`, `hashCode` and `runtimeType`;
- entity-derived types that collide with fixed AppForge-owned types such as `DomainReference`, `AppDatabase` or sync contracts;
- collisions between generated entity, repository, use-case, view-model and offline implementation type names.

Collision errors retain both relevant definition IDs whenever two project definitions conflict. AppForge does not silently append suffixes or rename one side of a collision.

This pre-render check complements `GenerationPlan` path validation: `GenerationPlan` remains the final filesystem-safety boundary, while the generated-contract validator can report the responsible business definitions before file emission.

## Atomic writer

`AtomicGeneratedProjectWriter` writes only a validated `GenerationPlan`.

It:

1. validates that the chosen parent exists and is writable;
2. refuses to overwrite an existing target;
3. creates a private staging directory inside the target parent;
4. writes the complete plan into staging;
5. verifies again that the target is still available;
6. atomically moves the completed staging tree into place;
7. cleans staging on failure.

Random staging directory names are filesystem implementation details and never appear in generated content.

## Determinism

Generated source must not contain:

- timestamps
- UUIDs
- host-specific absolute paths
- registry iteration order
- unresolved package versions

`appforge.generated.json` records the renderer version, project schema version, generated package name, resolved Forge package IDs, and the sorted generated file list.

## Current boundary

M3.11 owns deterministic domain contracts, stable record identity across generated read paths, offline mappings, generated-contract collision validation, and field-based Flutter form screens. Navigation/route materialization, relation placement in screens, list/detail/dashboard/settings/custom screens, create-ID policy, repository submit wiring, and provider backend rendering remain later slices.

Native iOS/Android platform scaffolding generated by the Flutter SDK must be treated separately because it depends on the exact Flutter toolchain version. A later bootstrap/build-validation slice will pin that external toolchain input rather than pretending those files are invariant across Flutter releases.

This distinction keeps the AppForge renderer reproducible while still allowing the final product to create buildable native targets through the verified Environment Doctor toolchain.
