# Verified Nix Bootstrap

## Purpose

M2.5 allows AppForge Pro to prepare a missing Nix installation on macOS without silently taking privileged control of the machine.

The bootstrap is intentionally guided:

```text
Environment Doctor
  ↓
Nix missing
  ↓
Prepare verified installer
  ↓
Show version + installer SHA-256 + system-change warning
  ↓
explicit user approval for that digest
  ↓
open controlled .command in visible Terminal
  ↓
official Nix installer requests sudo interactively
  ↓
Environment Doctor re-checks Nix
```

## Pinned release policy

The current policy is versioned in source code.

Current bootstrap:

- Nix 2.35.2
- `https://releases.nixos.org/nix/nix-2.35.2/install`
- x86_64-darwin tarball SHA-256:
  `d725518d89f3b0b8d4af702a9d38d519814014cbe125afb3ed0545c9d755f6a5`
- aarch64-darwin tarball SHA-256:
  `1695c13aba5afa7c2ecd6dc4a9393f602e7bbc440ed45e81602c831546580ec3`

A Nix release update must be reviewed as a dedicated change. The mutable latest installer URL is not used by the bootstrap policy.

## Download boundary

The downloader requests only the pinned HTTPS URL.

Preparation rejects:

- a response that resolves to a different URL;
- a non-200 HTTP response;
- an empty installer;
- an installer larger than the configured maximum;
- invalid UTF-8;
- missing release markers;
- missing x86_64 Darwin tarball hash;
- missing aarch64 Darwin tarball hash.

The downloaded installer is hashed with SHA-256.

## Prepared workspace

After validation AppForge creates an isolated temporary workspace:

```text
.appforge-nix-bootstrap-<UUID>/
├── install.sh
└── install.command
```

The workspace is created only after the downloaded bytes pass release validation.

`install.command` is generated entirely by AppForge and contains no user-supplied path:

```sh
#!/bin/sh
set -eu
SCRIPT_DIR="$(CDPATH= cd "$(dirname "$0")" && pwd)"
exec /bin/sh "$SCRIPT_DIR/install.sh" --daemon
```

AppForge never generates `curl | sh` and never uses `sh -c`.

## Digest-bound approval

The UI layer must display at least:

- Nix release version;
- installer SHA-256;
- that the multi-user installer performs privileged system changes;
- that Terminal and sudo interaction will be visible.

Approval creates a `NixBootstrapConfirmation` for the exact prepared installer SHA-256.

A confirmation for any other digest is rejected before launch.

## Pre-launch revalidation

Immediately before Terminal launch AppForge:

1. validates that workspace paths still point to the controlled bootstrap directory;
2. verifies that `install.command` is byte-identical to the AppForge template;
3. reloads `install.sh`;
4. validates the installer structure and pinned Darwin hashes again;
5. recomputes SHA-256;
6. compares it with the approved prepared digest.

Any mismatch prevents launch.

## Privilege boundary

AppForge itself does not run `sudo`.

The application opens the verified `.command` file using:

```text
/usr/bin/open -a Terminal <verified-command-path>
```

The visible Terminal session runs the official version-pinned Nix installer. The installer itself performs its documented interactive privilege escalation.

This is deliberately different from an invisible privileged helper.

## Cleanup

A cleanup use case can remove only a validated AppForge bootstrap workspace.

Arbitrary paths are rejected.

The workspace must remain available while Terminal needs the installer. Cleanup happens after installation or cancellation.

## Follow-up UI

The Studio setup flow still needs to connect these core use cases:

1. detect missing Nix;
2. offer `Nix Reproducible`;
3. display system-change warning;
4. prepare installer;
5. show release + SHA-256;
6. require explicit confirmation;
7. launch Terminal;
8. offer `Erneut prüfen`;
9. run Environment Doctor;
10. continue Nix environment provisioning only after Nix reports ready.

## Future hardening

A later fully embedded privileged installation would require a dedicated macOS privileged-helper architecture and a separate security review. It must not be implemented by hiding shell commands behind the GUI.
