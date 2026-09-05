# Package System

## Purpose

The package system is the deterministic boundary between a validated `ProjectSpecification` and every renderer. Business templates and vertical rules request packages and capabilities; they do not emit Flutter, SwiftUI, Compose, SQL, or shell fragments.

```text
validated ProjectSpecification
        +
package requests
        ↓
PackageRegistry
        ↓
PackageResolver
        ↓
ResolvedProductGraph
        +
forge.lock
        ↓
renderer
```

A renderer must consume the resolved graph. It must not query an unresolved registry or silently add packages during generation.

## Package contract

`ForgePackageContract` describes one immutable package version. The contract contains:

- stable namespaced package ID
- semantic version
- package kind
- package dependencies with version constraints
- required and provided capabilities
- explicit package conflicts
- supported output frameworks and backends
- maturity level
- source provenance

Package and capability IDs use lowercase namespaced identifiers such as `feature.inventory` and `identity.current_user`. Display labels belong to product/template presentation and are not dependency identifiers.

## Semantic versions

Package versions use `ForgeSemanticVersion`, a package-specific SemVer implementation. It intentionally does not reuse the simpler toolchain version type because package resolution needs prerelease and build-metadata semantics.

The resolver chooses the highest compatible precedence. When two version strings have equal SemVer precedence because only build metadata differs, a stable textual tie-breaker is used so registry input order cannot change resolution output.

## Source provenance

Supported source kinds in M3.1:

- `bundled`: shipped as part of the trusted AppForge distribution
- `github`: repository + explicit reference + SHA-256

GitHub contracts without a repository, reference, or 64-character lowercase SHA-256 are rejected before resolution. Resolution never executes package code or install scripts.

Remote download, cache management, signatures, and trust policies are later capabilities. They must preserve this contract and lockfile boundary.

## Resolution rules

The resolver:

1. receives explicit root package requests;
2. accumulates all version constraints for each package;
3. validates registry contracts;
4. filters by framework and backend compatibility;
5. resolves transitive dependencies with deterministic backtracking;
6. rejects package conflicts;
7. validates that every required capability is provided by the final graph;
8. rejects dependency cycles;
9. returns packages in deterministic dependency-first order.

Resolution failures are typed `PackageResolutionError` values. There is no fallback to a different backend/framework and no silent correction of invalid contracts.

## ProjectSpecification boundary

`ResolveProductPackagesUseCase` validates `ProjectSpecification` before any package resolution. An invalid project specification never reaches the resolver or a renderer.

Packages may restrict `OutputFramework` and `BackendProvider`. Empty compatibility lists mean that a package is renderer/backend agnostic. A package that declares compatibility must match the current specification before it can be selected.

## Bundled production registry

AppForge ships a minimal trusted `BundledPackageRegistry` as the production bootstrap registry for M3.

The first bundled contract is:

- `foundation.core@1.0.0`
- kind: `foundation`
- maturity: `stable`
- source: `bundled`
- renderer compatibility: Flutter
- backend compatibility: unrestricted

The default root request set contains `foundation.core`.

The bundled registry is deliberately small. Business templates, vertical overlays, and future capability mapping expand the root request set; they do not bypass the resolver and they do not inject source files directly.

All bundled contracts are constructed through the same `InMemoryPackageRegistry` validation boundary used by tests and other registries. Invalid bundled metadata therefore fails closed rather than being treated as trusted merely because it ships with AppForge.

## End-to-end generation boundary

`BuildFlutterProjectUseCase` composes the existing deterministic stages:

```text
validated ProjectSpecification
+ root package requirements
+ PackageRegistry
+ Flutter materialization toolchain
+ target URL
        ↓
ResolveProductPackagesUseCase
        ↓
ResolvedProductGraph + forge.lock
        ↓
FlutterProjectRendering
        ↓
GenerationPlan
        ↓
FlutterProjectMaterializing
        ↓
native Flutter project
```

The orchestrator contains no alternative resolver, renderer, or materializer logic.

If package resolution or rendering fails, materialization is never invoked. Direct-SDK and Nix-backed toolchain selections are passed through unchanged to the M3.4 materializer.

## ResolvedProductGraph

`ResolvedProductGraph` is the renderer-facing package result. It contains the exact resolved contracts in dependency-first order and the complete sorted capability set.

Renderer implementations must not:

- resolve new package versions;
- mutate the graph;
- execute package installation hooks;
- add template-specific code paths outside package/capability contracts;
- rewrite generated source with post-generation string replacement.

## forge.lock

`ForgeLockfile` is schema-versioned and defaults to the filename `forge.lock`. Each entry records:

- package ID and exact version
- kind and maturity
- exact resolved dependencies
- provided capabilities
- source provenance, including remote reference and checksum

`ForgeLockfileCodec` uses sorted JSON keys and normalized package/dependency/capability ordering. For identical validated inputs, the lockfile bytes are identical.

The lockfile is an output of resolution, not user-authored business configuration. A future upgrade engine will compare an existing lockfile with a newly resolved graph and surface migrations instead of silently changing generated applications.

## Security rules

- no executable content in package contracts
- no install scripts during resolution
- no unpinned GitHub package in a valid remote contract
- invalid contracts fail closed
- incompatible framework/backend combinations fail before rendering
- unresolved capability requirements fail before rendering
- conflicts and cycles fail before rendering
- renderers consume only a resolved graph

## M3.1 quality contract

The first package-system slice is complete only when tests cover:

- SemVer precedence and invalid versions
- contract/source validation
- transitive dependencies
- multi-constraint backtracking
- framework/backend incompatibility
- missing capabilities
- conflicts
- dependency cycles
- invalid `ProjectSpecification` rejection
- byte-identical `forge.lock` generation

Remote package acquisition and the deterministic Flutter file renderer are deliberately separate slices so network/supply-chain behavior cannot contaminate the resolver core.
