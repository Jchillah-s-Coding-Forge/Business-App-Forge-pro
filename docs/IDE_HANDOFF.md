# IDE Handoff

## Purpose

AppForge Pro generates a normal standalone Flutter source tree. IDE integration is a handoff after generation, never a runtime dependency of the generated application.

After a successful production generation the user can open the exact generated project root in a supported development environment.

## Supported destinations

| Destination | Bundle identifier | Availability |
| --- | --- | --- |
| Visual Studio Code | `com.microsoft.VSCode` | detected |
| Android Studio | `com.google.android.studio` | detected |
| Xcode | `com.apple.dt.Xcode` | detected |
| Terminal | `com.apple.Terminal` | detected |
| Finder | system service | always available |
| System default | LaunchServices default | always available |

`System default` means macOS opens the generated directory with its configured default handler. It is not presented as an interactive `Open With...` chooser.

## Detection

IDE availability does not depend on a shell command being present on `PATH`.

AppForge uses two signals:

1. known macOS application locations;
2. Spotlight metadata lookup by exact application bundle identifier.

Known locations include the system-wide `/Applications` folder and the user's `~/Applications` folder where applicable.

The locator returns the actual `.app` path. A CLI such as `code` by itself is not treated as proof that the corresponding GUI application is installed.

Finder and System default are safe OS-level fallbacks and are therefore always exposed.

## Preferred IDE

`ToolchainPreferences.preferredIDE` persists the user's preferred destination.

Supported preference values are:

- VS Code
- Android Studio
- Xcode
- Finder
- Terminal
- Systemstandard

Existing preference payloads remain compatible because existing raw values are unchanged.

When Project Setup opens, it detects current application availability. The preferred IDE is the primary post-generation action only when it is currently available.

If the preferred IDE is missing, AppForge:

- shows that it was not found;
- disables the preferred action;
- exposes detected alternatives;
- does not silently switch to Finder or another IDE.

## Command contract

All GUI handoffs use the existing bounded `/usr/bin/open` process boundary.

AppForge does not build shell command strings.

### VS Code

```text
/usr/bin/open
  -b com.microsoft.VSCode
  <generated-project-root>
```

### Android Studio

```text
/usr/bin/open
  -b com.google.android.studio
  <generated-project-root>
```

### Xcode

```text
/usr/bin/open
  -b com.apple.dt.Xcode
  <generated-project-root>
```

### Terminal

```text
/usr/bin/open
  -b com.apple.Terminal
  <generated-project-root>
```

### Finder

```text
/usr/bin/open
  -R
  <generated-project-root>
```

### System default

```text
/usr/bin/open
  <generated-project-root>
```

The project path is supplied as one argument. It is never interpolated into `sh -c`.

## Project root contract

The handoff receives the final path returned by the production Flutter materializer.

That root is the complete Flutter project and contains the generated `pubspec.yaml`, native platform shells and AppForge receipts.

VS Code and Android Studio therefore receive the full Flutter project root rather than a generated subdirectory.

For Apple-specific work Xcode receives the same root. Selecting a native Xcode workspace/project inside the generated iOS shell remains an IDE-level action.

## Flutter SDK consistency

The IDE handoff does not select or replace the Flutter SDK.

The production generation has already resolved and validated one explicit execution mode:

- direct Flutter SDK, or
- verified Nix environment.

The IDE launch is a post-generation navigation action only. It never changes the generation toolchain or generated files.

## Error handling

`SystemMacOSOpenCommandRunner` waits for `/usr/bin/open` to exit.

A launch failure or non-zero exit is propagated to Project Setup and displayed as a user-visible error.

No alternate IDE is opened automatically after a failure.

## Security and ownership

The handoff must not:

- execute through a shell;
- mutate the generated project;
- rewrite IDE configuration files;
- inject a different Flutter SDK;
- silently choose another IDE;
- require a proprietary AppForge runtime.

The generated source tree remains fully editable and can always be opened independently of AppForge.

## Test contract

Automated coverage includes:

- bundle-aware availability detection;
- known-path detection;
- Finder and System default fallback availability;
- exact bundle-ID command construction;
- project-root argument preservation;
- all supported preferred IDE values;
- non-zero `open` propagation;
- unavailable preferred IDE does not trigger fallback;
- explicit alternate handoff from Project Setup.
