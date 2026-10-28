# Quick start

## Requirements

- Node.js 22 or newer for the example TypeScript build.
- ZIP utility (`zip`) to package the output.
- HeadyPanel admin access to upload a package.

## 1. Create a project

```bash
mkdir hello-extension && cd hello-extension
mkdir -p src dist
```

Create `heady-extension.json`:

```json
{
  "id": "hello-extension",
  "name": "Hello Extension",
  "version": "1.0.0",
  "description": "A minimal example package for HeadyPanel.",
  "apiVersion": "1",
  "entry": "dist/index.js",
  "permissions": []
}
```

Create `src/index.ts`:

```ts
/**
 * Example extension entrypoint.
 *
 * This function is intentionally not auto-discovered or executed by the panel.
 * It demonstrates a portable module shape for future SDK runtime integration.
 */
export function register(): { id: string; message: string } {
    return {
        id: 'hello-extension',
        message: 'Hello from a HeadyPanel extension!',
    };
}
```

## 2. Build

Use a local TypeScript compiler:

```bash
npm init -y
npm install --save-dev typescript
npx tsc src/index.ts --target ES2022 --module ES2022 --outDir dist --strict
```

If your compiler configuration emits a different file name, ensure `dist/index.js` exists before packaging.

## 3. Package

From the project directory, create a ZIP with the manifest at the archive root:

```bash
zip -r hello-extension-1.0.0.zip heady-extension.json README.md src dist
```

Do not ZIP the parent directory itself; `heady-extension.json` must be at the ZIP root.

## 4. Upload

1. Sign in as a root administrator.
2. Open **Admin → Extensions** at `/admin/extensions`.
3. Select the ZIP and click **Upload package**.
4. Review the package ID and version.
5. Use Enable/Disable to change its registry state, or Remove to delete it.

Upload validates package metadata and stores the archive. It does not execute `dist/index.js`. A future runtime adapter must explicitly implement the SDK contract before this example can add functionality to the panel.
