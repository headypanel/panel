# Security model

Extensions are third-party code and must be treated as untrusted input.

## Current safeguards

- Admin routes are protected by the existing admin middleware stack.
- Upload is limited to ZIP files and 10 MiB.
- Archive entries are capped at 500 and individual uncompressed files at 20 MiB.
- The manifest is parsed as JSON and required metadata is validated.
- Path traversal and backslash-based paths are rejected.
- Artifacts are stored on the private local disk.
- Uploaded source is never included, evaluated, or executed by the current manager.

## Not yet implemented

- Malware scanning or cryptographic publisher signatures.
- Dependency vulnerability scanning for extension packages.
- Runtime permission enforcement.
- Process/container isolation for executing extensions.
- Automatic rollback and database migration sandboxing.
- Frontend extension route registration.

Never enable an extension solely because its manifest looks valid. A valid manifest is not a security review. Before a runtime is introduced, run extension code outside the web worker under a dedicated OS identity/container with restricted network, filesystem, CPU, memory, and execution time. Use explicit capability grants, audit logs, signed artifacts, and a kill switch.
