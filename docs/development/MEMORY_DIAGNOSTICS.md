# Memory Diagnostics

## Purpose

AppForge Pro uses macOS system services that may retain Foundation, AppKit and XPC objects beyond the lifetime of one UI action.

A Memory Graph snapshot must therefore distinguish between:

1. an AppForge-owned retention cycle that grows with repeated use;
2. a bounded system/framework retention used by macOS services.

A single object marked as leaked is not sufficient evidence of an AppForge-owned leak.

## Known XPC boundary

`NSOpenPanel` and `NSSavePanel` are system file-selection surfaces.

On modern macOS the save/open dialog can be hosted out-of-process. Foundation/AppKit may therefore own XPC objects such as:

- `NSXPCConnection`
- `NSXPCInterface`
- XPC reply tables
- dispatch mach/group objects
- Foundation collection/data storage

AppForge must never manually invalidate private XPC objects that it did not create.

## AppForge-owned process boundary

AppForge also performs macOS handoffs through `/usr/bin/open` for:

- opening a generated project in the selected IDE;
- opening an external setup URL;
- opening the verified Nix bootstrap command in Terminal.

These handoffs use one shared `SystemMacOSOpenCommandRunner`.

The runner:

1. creates exactly one `Process`;
2. starts `/usr/bin/open`;
3. waits for that child process to terminate;
4. checks its termination status;
5. returns only after the `Process` lifecycle is closed.

There is no shell and no `sh -c`.

## Reproduction protocol

Use a Debug build and repeat the same sequence for every comparison.

### Baseline

1. Launch AppForge Pro.
2. Do not open any file/save panel.
3. Do not open a setup URL, generated project or Terminal handoff.
4. Wait for the initial Environment Doctor scan to finish.
5. Capture Memory Graph snapshot A.

### File panel

1. Open exactly one `NSOpenPanel` or `NSSavePanel`.
2. Cancel or complete the panel.
3. Capture snapshot B.
4. Repeat the same panel action ten times.
5. Capture snapshot C.

Interpretation:

- a small XPC count that stays bounded is treated as framework/system retention;
- a count that increases approximately once per panel invocation requires a dedicated panel-lifecycle investigation.

### macOS open handoff

1. Start from a fresh launch.
2. Trigger one AppForge handoff through the external URL, project opener or Nix Terminal flow.
3. Wait for the launched handoff process to exit.
4. Capture a snapshot.
5. Repeat ten times.

The number of AppForge-owned `Process` instances must return to zero after each completed handoff.

## URLSession

AppForge uses `URLSession.shared` for official Flutter and Nix downloads.

The shared session is intentionally process-scoped. Network/XPC support objects may remain alive while the application runs.

A suspected network leak must be verified by repeated download operations and resident-memory/object-count growth. Do not create and invalidate one new URLSession per request solely to make a Memory Graph snapshot smaller.

## Escalation criteria

Create a product bug only when one or more of these conditions are reproducible:

- AppForge-owned objects form the retaining cycle.
- A class count grows monotonically with identical completed actions.
- Resident memory grows materially and does not settle after repeated actions.
- A `Process`, file handle or Task remains alive after its operation completed.
- Instruments Leaks identifies allocations with an AppForge stack rather than only AppKit/Foundation/XPC frames.

When only Apple framework objects remain and their counts are bounded, document the observation instead of changing product architecture to hide the diagnostic.
