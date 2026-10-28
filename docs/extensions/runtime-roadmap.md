# Runtime integration roadmap

The SDK defines the package format and extension authoring contract. A secure, production extension runtime requires a separate host implementation.

## Runtime capabilities not included in this release

- Frontend navigation and page contributions.
- Backend event hooks and application service APIs.
- Permission prompts and enforced capabilities.
- Lifecycle callbacks invoked by the panel.
- Sandboxed execution, quotas, timeouts, and revocation.
- Extension database migrations and rollback.
- Compatibility checks at activation time.

## Required design before execution is enabled

1. Execute untrusted extension code outside PHP-FPM and outside the panel's trusted process.
2. Use a dedicated worker identity or container with read-only base filesystem, restricted network egress, CPU/memory/time limits, and no panel secrets.
3. Expose a narrow RPC capability API with per-extension permissions and audit logging.
4. Validate package signatures and hashes; keep immutable versioned artifacts and rollback support.
5. Test malicious archives, permission escalation, timeout, worker crashes, and host upgrades.
6. Keep the admin manager's enable toggle as metadata until all controls above exist.

A package manager alone is not a plugin runtime. This roadmap is intentional so enabling an upload cannot silently become arbitrary code execution.
