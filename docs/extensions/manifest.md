# Manifest reference

Every extension archive contains `heady-extension.json` at its root.

## Required fields

| Field | Type | Requirements |
| --- | --- | --- |
| `id` | string | 3–64 chars, lowercase letters/numbers/hyphens, starts with a letter |
| `name` | string | Human-readable name |
| `version` | string | Semantic version, e.g. `1.2.3` |
| `description` | string | Short summary |
| `apiVersion` | string | SDK/API compatibility version |

## Optional fields

| Field | Type | Meaning |
| --- | --- | --- |
| `entry` | string | Intended module entrypoint; not loaded by the current panel |
| `permissions` | string[] | Requested permissions for future runtime support; not currently enforced |
| `author` | string | Publisher |
| `homepage` | string | Project URL |
| `license` | string | SPDX identifier |

Example:

```json
{
  "id": "server-notes",
  "name": "Server Notes",
  "version": "1.2.0",
  "description": "Adds notes to server management workflows.",
  "apiVersion": "1",
  "entry": "dist/index.js",
  "permissions": [],
  "author": "Example Publisher",
  "license": "MIT"
}
```

IDs are immutable once published. Publish breaking changes as a major version. Keep the `apiVersion` separate from the extension's own version.
