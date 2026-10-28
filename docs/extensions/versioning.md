# Compatibility and versioning

HeadyPanel extension packages use semantic versioning for their own releases and a separate `apiVersion` for the extension API.

- **Patch**: compatible bug fixes.
- **Minor**: backward-compatible features.
- **Major**: breaking changes to the extension's public interface.
- **API version**: increment only when the host contract changes incompatibly.

The current manager stores `apiVersion` as descriptive metadata; it does not yet enforce compatibility or load the extension entrypoint. Check the host release notes before shipping packages and test on a staging instance first.
