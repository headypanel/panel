# Build and package

## Recommended workflow

1. Keep source code under `src/`.
2. Compile to `dist/`; do not include `node_modules/`, secrets, environment files, or local caches.
3. Validate `heady-extension.json` with a JSON parser.
4. Build a ZIP with the manifest at its root.
5. Record a SHA-256 checksum and retain the exact release artifact.

Example:

```bash
node -e "JSON.parse(require('fs').readFileSync('heady-extension.json', 'utf8')); console.log('manifest OK')"
npm ci
npm run build
zip -r extension-1.0.0.zip heady-extension.json README.md dist
sha256sum extension-1.0.0.zip
```

Example `package.json` scripts:

```json
{
  "private": true,
  "scripts": {
    "build": "tsc -p tsconfig.json"
  },
  "devDependencies": {
    "typescript": "^5.7.0"
  }
}
```

## Packaging rules

- Archive root must contain `heady-extension.json`.
- Use relative paths only; never include absolute paths or `..` traversal.
- Keep packages small; the admin upload limit is 10 MiB.
- Include license and attribution notices for bundled dependencies.
- Avoid shipping development source maps if they expose private paths.
- Treat packages as immutable releases; upload a new version using the same ID only after the existing package is removed (current manager limitation).
