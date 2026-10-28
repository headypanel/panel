# @headypanel/extension-sdk

Developer toolkit for building HeadyPanel extension packages. Requires Node.js 22+.

## Install locally

From this directory:

```bash
npm install
npm link
heady-ext help
```

## Create, validate, package

```bash
heady-ext init ./my-extension --id my-extension
cd my-extension
# Build your dist/ using your chosen bundler.
heady-ext validate
heady-ext pack --out ../my-extension-1.0.0.zip
```

Commands can also be invoked without `npm link`:

```bash
node ../packages/extension-sdk/bin/heady-ext.js validate .
```

## Contract

Export a definition using `defineExtension({ id, name, version, activate, deactivate? })`. The context contract is documented in `src/index.js`. Permissions are declarative metadata only today.

**Runtime status:** the HeadyPanel admin manager currently validates and stores ZIP packages, but does not import, execute, or sandbox extension code. Do not treat the SDK contract as a live host API until runtime integration ships.
