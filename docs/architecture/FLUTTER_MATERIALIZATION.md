# Flutter Materialization

## Purpose

M3.2 owns deterministic AppForge source rendering. M3.3 turns that source tree into a complete Flutter application with native platform shells by making the selected Flutter SDK an explicit, validated toolchain input.

```text
ProjectSpecification
+ ResolvedProductGraph
+ forge.lock
+ GenerationPlan
+ selected Flutter SDK
        ↓
target + plan validation
        ↓
Flutter SDK inspection
        ↓
private staging root
        ↓
flutter create --empty --no-pub
        ↓
remove bootstrap app-owned files
        ↓
overlay AppForge GenerationPlan
        ↓
flutter pub get
        ↓
flutter analyze
        ↓
flutter test
        ↓
pubspec.lock SHA-256
+ appforge.toolchain.json
        ↓
atomic final move
```

The final target is never used as a working directory. It appears only after all validation gates succeed.

## Toolchain identity

The selected SDK path is validated as a directory containing an executable `bin/flutter`. AppForge never replaces that selection with a different `flutter` found on `PATH`.

The inspector executes the selected binary with machine-readable version output and records:

- Flutter version
- channel
- framework revision
- engine revision
- Dart SDK version

Framework and engine revisions must be Git-style hexadecimal revisions. The reported Flutter version must satisfy AppForge's supported minimum.

Absolute SDK paths are runtime-only metadata and are deliberately excluded from the generated receipt.

## Shell-free command execution

`SystemToolchainCommandRunner` invokes `Foundation.Process` with:

- an absolute executable path
- an argument array
- an explicit working directory
- a whitelisted environment
- a timeout

It never builds a shell command and never calls `/bin/sh -c`.

The Flutter process environment contains only the values required for predictable CLI execution:

- selected Flutter SDK `bin` first on `PATH`
- standard system binary paths
- `CI=true`
- deterministic terminal/locale values
- `PUB_ENVIRONMENT=appforge`
- inherited `HOME` and `TMPDIR` when present

Secrets and arbitrary parent-process environment variables are not forwarded.

## Bounded diagnostics

stdout and stderr are captured into a private temporary file rather than an unbounded in-memory pipe.

After termination AppForge:

1. reads at most the final 64 KiB;
2. marks truncated output;
3. removes ANSI terminal escapes;
4. removes unsafe control characters;
5. deletes the temporary capture file.

This prevents large tool output from becoming an unbounded memory or UI payload while preserving useful failure context.

## Timeout behavior

Each Flutter step has an explicit timeout.

If a process exceeds the limit:

1. AppForge sends normal termination;
2. waits a short grace period;
3. sends SIGKILL only if the process is still running;
4. waits for termination;
5. returns a typed timeout failure.

No background Flutter process is intentionally left behind after a timed-out materialization step.

## Bootstrap strategy

Flutter owns native shell generation. AppForge owns application source.

The materializer asks Flutter to create a minimal application with:

- `--empty`
- `--no-pub`
- explicit `--project-name`
- explicit `--org`
- explicit `--platforms`

The create command operates inside a private staging parent and creates a fixed child directory named `project`.

After bootstrap, AppForge removes app-owned bootstrap artifacts that could conflict with the deterministic renderer:

- `lib/`
- `test/`
- `analysis_options.yaml`
- any bootstrap `pubspec.lock`
- any bootstrap `.dart_tool/`

Native shells and Flutter metadata remain intact.

The validated M3.2 `GenerationPlan` is then overlaid using the same path-safe `GenerationPlanFileWriter` used by the standalone source exporter.

## Plan consistency

The materializer does not trust an arbitrary supplied file plan.

Before any SDK process runs, it re-renders the expected plan from:

- `ProjectSpecification`
- `ResolvedProductGraph`
- `forge.lock`

The supplied `GenerationPlan` must be exactly equal to that expected plan. A stale, substituted, or mismatched plan fails before staging.

## Validation gates

After overlay, AppForge runs the selected SDK binary directly for:

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`

Any non-zero exit code or timeout aborts the materialization.

Release builds, signing, provisioning, simulators, devices, and store upload are intentionally later Quality / Release Center responsibilities.

## Dependency lock provenance

The final application keeps `pubspec.lock` under version control.

After `flutter pub get`, AppForge computes SHA-256 over the resulting lockfile and records the digest in `appforge.toolchain.json`.

This makes the exact dependency resolution auditable even when package registries change later.

## Toolchain receipt

`appforge.toolchain.json` is deterministic for the materialized toolchain/dependency state and contains:

- receipt schema version
- Flutter toolchain identity
- generated Dart package name
- organization identifier
- deterministically ordered target platforms
- SHA-256 of `pubspec.lock`
- successfully completed validation steps

It contains no:

- timestamps
- UUIDs
- local absolute paths
- environment dumps
- secrets
- command output

## Atomic publication

The final target must not exist.

All work occurs under:

```text
<target-parent>/.appforge-materialize-<ephemeral-id>/project
```

The ephemeral directory name never enters generated content.

Only after the receipt is written and every gate has passed is the completed `project` directory moved to the requested final target.

On failure, AppForge removes the complete staging root. If cleanup itself fails, that failure is surfaced rather than silently hidden.

## M3.3 quality contract

The slice is complete only when tests cover:

- selected-SDK execution instead of PATH fallback
- machine-readable SDK identity parsing
- incompatible and malformed SDK rejection
- direct binary execution without a shell
- bounded / sanitized output
- process timeout termination
- exact create arguments and target-platform mapping
- preservation of native shells
- removal of conflicting bootstrap app code
- GenerationPlan mismatch rejection
- `pub get` / `analyze` / `test` gating
- dependency-lock hashing
- receipt round-trip without local paths
- existing-target no-overwrite
- failure cleanup with no published partial project
