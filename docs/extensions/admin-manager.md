# Admin Extension Manager

The manager is available to administrators at `/admin/extensions`.

## Supported actions

- Upload a ZIP package.
- Validate the ZIP and root manifest.
- Reject malformed JSON, invalid IDs, missing required metadata, unsafe paths, too many files, and oversized entries.
- List package name, ID, version, API version, and registry state.
- Toggle the registry state.
- Remove a package.

## Storage

Artifacts and metadata are stored on Laravel's private local disk under `storage/app/heady-extensions/{id}/`. They are not served as public static files.

## Important limitation

The current manager is a package registry, not a code execution environment. Toggling “Enabled” does not load code. Runtime activation, extension-provided UI, migrations, event hooks, dependency resolution, and sandboxing are not implemented yet. This limitation is intentional: evaluating arbitrary PHP/JavaScript from an upload would create a remote-code-execution path.
