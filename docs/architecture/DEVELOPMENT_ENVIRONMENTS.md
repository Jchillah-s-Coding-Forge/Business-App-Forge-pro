# Development Environments

## Goal

AppForge Pro supports multiple ways to satisfy a generated project's development toolchain without coupling product generation to one machine setup.

The environment model has three explicit modes:

```text
DevelopmentEnvironmentMode
├── appForgeManaged
├── existingToolchain
└── nixReproducible
```

Nix is optional. A missing Nix installation must never block normal AppForge Managed or Existing Toolchain workflows.

## AppForge Managed

AppForge Managed remains the default user experience.

AppForge selects, validates and uses the supported SDK/toolchain paths required by the existing generation/materialization pipeline.

This mode does not depend on Nix.

## Existing Toolchain

Existing Toolchain uses compatible tools already installed by the user and detected by the Environment Doctor.

The existing readiness rules continue to apply.

## Nix Reproducible

Nix Reproducible creates a project-scoped reproducible development environment.

The current M2.4 scope provisions portable command-line dependencies:

- Git
- Flutter
- JDK 17 for Android targets

It supports:

- `aarch64-darwin`
- `x86_64-darwin`

The environment is represented by:

```text
NixEnvironmentPlan
       ↓
flake.nix
       ↓
nix flake lock
       ↓
flake.lock
       ↓
nix develop --command flutter --version
       ↓
appforge.nix-environment.json
```

## Managed boundary

Not every platform dependency belongs in Nix.

For iOS targets:

- Xcode remains Apple/system managed.
- Apple SDKs, simulators, code signing and provisioning remain outside Nix.

For Android targets in M2.4:

- JDK 17 may come from Nix.
- Android SDK remains outside Nix.
- Android SDK license acceptance is not automated in this slice.

The generated `NixEnvironmentReceipt` records those unmanaged requirements so the boundary is auditable.

## Nix detection

Nix is an optional Environment Doctor tool.

Detection checks:

1. the inherited executable search path;
2. the standard multi-user macOS path `/nix/var/nix/profiles/default/bin/nix`.

The minimum supported Nix version for this slice is 2.4.

If Nix is missing, AppForge provides an official setup handoff. The application does not silently perform a system-wide Nix installation.

## Flake feature activation

AppForge does not mutate global `nix.conf`.

Commands enable the required features per invocation:

```text
nix
  --extra-experimental-features "nix-command flakes"
  flake lock
```

and:

```text
nix
  --extra-experimental-features "nix-command flakes"
  develop
  --command flutter
  --version
```

## Shell-free execution

Nix provisioning uses the same bounded `ToolchainCommandRunning` process boundary introduced for Flutter materialization.

AppForge passes:

- an absolute executable path;
- an argument array;
- an explicit working directory;
- a reduced environment;
- a timeout.

It does not construct `/bin/sh -c` command strings.

Sensitive inherited variables such as repository/API tokens are not copied into the process environment.

## Atomic provisioning

Provisioning uses a staging directory.

```text
target parent
  ↓
.appforge-nix-<temporary>/
  └── environment/
      ├── flake.nix
      ├── flake.lock
      └── appforge.nix-environment.json
```

The final target is published only after all of these steps succeed:

1. write deterministic `flake.nix`;
2. validate Nix version;
3. run `nix flake lock`;
4. parse and validate the locked nixpkgs revision;
5. hash `flake.lock` with SHA-256;
6. validate Flutter through `nix develop`;
7. write the environment receipt.

Any failure removes the staging directory and leaves the target unpublished.

An existing target fails before Nix is executed.

## Determinism and provenance

`flake.nix` is deterministic for the same `NixEnvironmentPlan`.

The moving nixpkgs input is not treated as provenance. Reproducibility begins at the produced `flake.lock`.

The lock inspector requires a valid locked nixpkgs Git revision and records:

- Nix version;
- locked nixpkgs revision;
- SHA-256 of `flake.lock`;
- supported systems;
- Nix-managed packages;
- intentionally unmanaged platform requirements;
- validation tool;
- validated Flutter version.

The receipt intentionally contains no absolute local paths.

## Security rules

The Nix provider must not:

- execute through a shell;
- call `sudo`;
- modify global `nix.conf`;
- silently install Nix;
- silently accept Android SDK licenses;
- store local absolute paths in the receipt;
- copy secrets into the Nix process environment;
- publish a partially validated environment.

## Follow-up slices

Not included in M2.4:

- explicitly approved macOS Nix bootstrap;
- Android SDK provisioning through Nix `androidenv`;
- explicit Android license acceptance UI;
- Studio UI for selecting the environment mode;
- CI reuse of the generated project flake;
- environment upgrade workflow;
- rollback/repair UI.
