# HeadyPanel Extension SDK

The HeadyPanel Extension SDK defines a versioned package format and development workflow for third-party extensions.

> **Current implementation boundary:** the admin manager can validate, upload, list, enable/disable registry entries, and remove ZIP packages. It does **not** execute extension code, register runtime hooks, add frontend routes, or isolate plugins in a sandbox. “Enabled” currently records administrative intent only. Do not deploy untrusted packages or assume they are active features.

## Documentation

- [Quick start](quick-start.md)
- [Manifest reference](manifest.md)
- [Package format and build](build-and-package.md)
- [Admin upload workflow](admin-manager.md)
- [Security model](security.md)
- [Compatibility and versioning](versioning.md)
- [Example extension](examples/hello-extension/README.md)
- [SDK runtime roadmap](runtime-roadmap.md)
- [Standalone SDK package and CLI](../../packages/extension-sdk/README.md)

## Design goals

- Explicit manifest and stable extension ID.
- Reproducible ZIP artifacts.
- Versioned HeadyPanel API compatibility.
- No implicit execution of uploaded code.
- Future runtime integration must be opt-in, permissioned, auditable, and isolated.

## Package layout

```text
hello-extension/
├── heady-extension.json
├── README.md
├── src/
│   └── index.ts
└── dist/
    └── index.js
```

The manifest must be at the ZIP root. The current manager accepts a ZIP up to 10 MiB, containing at most 500 entries, with individual entries capped at 20 MiB. The manifest fields `id`, `name`, `version`, `description`, and `apiVersion` are required.
