#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { createRequire } from 'node:module';
import archiver from 'archiver';
import { MANIFEST_FILE, SDK_API_VERSION, validateManifest } from '../src/manifest.js';

const require = createRequire(import.meta.url);
const packageVersion = require('../package.json').version;

function usage() {
    console.log(`HeadyPanel Extension SDK v${packageVersion}

Usage:
  heady-ext init <directory> [--id extension-id]
  heady-ext validate [directory]
  heady-ext pack [directory] [--out file.zip]

Commands:
  init      Create a minimal TypeScript extension project.
  validate  Validate heady-extension.json and entrypoint paths.
  pack      Validate and create a distributable ZIP package.
`);
}

function option(args, name, fallback) {
    const index = args.indexOf(name);
    return index >= 0 && args[index + 1] ? args[index + 1] : fallback;
}

async function readManifest(directory) {
    const file = path.join(directory, MANIFEST_FILE);
    let manifest;
    try {
        manifest = JSON.parse(await fs.readFile(file, 'utf8'));
    } catch (error) {
        throw new Error(`Cannot read ${file}: ${error.message}`);
    }
    const result = validateManifest(manifest);
    if (!result.valid) throw new Error(result.errors.join('\n'));
    if (manifest.entry) {
        const entry = path.resolve(directory, manifest.entry);
        if (!entry.startsWith(path.resolve(directory) + path.sep)) {
            throw new Error('entry must stay inside the extension directory.');
        }
        await fs.access(entry);
    }
    return manifest;
}

async function init(directory, args) {
    const id = option(args, '--id', path.basename(path.resolve(directory)).toLowerCase().replace(/[^a-z0-9-]+/g, '-').replace(/^-+|-+$/g, '') || 'my-extension');
    if (!/^[a-z][a-z0-9-]{2,63}$/.test(id)) throw new Error('Invalid --id. Use 3–64 lowercase letters, numbers, or hyphens.');
    await fs.mkdir(path.join(directory, 'src'), { recursive: true });
    await fs.mkdir(path.join(directory, 'dist'), { recursive: true });
    const manifest = {
        id, name: id.split('-').map((part) => part[0]?.toUpperCase() + part.slice(1)).join(' '),
        version: '1.0.0', description: 'A HeadyPanel extension.', apiVersion: SDK_API_VERSION,
        entry: 'dist/index.js', permissions: []
    };
    await fs.writeFile(path.join(directory, MANIFEST_FILE), JSON.stringify(manifest, null, 2) + '\n', { flag: 'wx' });
    await fs.writeFile(path.join(directory, 'src/index.js'),
        "import { defineExtension } from '@headypanel/extension-sdk';\n\nexport default defineExtension({\n" +
        `    id: '${id}',\n    name: '${manifest.name}',\n    version: '1.0.0',\n` +
        "    async activate(context) {\n        context.logger.info('Extension activated');\n    },\n});\n",
        { flag: 'wx' });
    await fs.writeFile(path.join(directory, 'README.md'),
        `# ${manifest.name}\n\nBuild with your preferred JavaScript bundler, then run ` +
        "`npx heady-ext validate` and `npx heady-ext pack`.\n\n" +
        "Note: the current HeadyPanel admin manager stores packages but does not execute their code.\n",
        { flag: 'wx' });
    console.log('Created extension project at ' + path.resolve(directory));
}

async function pack(directory, output) {
    const manifest = await readManifest(directory);
    const out = path.resolve(output || `${manifest.id}-${manifest.version}.zip`);
    if (out.startsWith(path.resolve(directory) + path.sep)) throw new Error('Output ZIP must be outside the extension source directory.');
    await fs.mkdir(path.dirname(out), { recursive: true });

    await new Promise((resolve, reject) => {
        const stream = fs.open(out, 'wx').then((handle) => handle.createWriteStream()).catch(reject);
        stream.then((outputStream) => {
            const archive = archiver('zip', { zlib: { level: 9 } });
            outputStream.on('close', resolve);
            outputStream.on('error', reject);
            archive.on('warning', (error) => error.code === 'ENOENT' ? console.warn(error.message) : reject(error));
            archive.on('error', reject);
            archive.pipe(outputStream);
            archive.file(path.join(directory, MANIFEST_FILE), { name: MANIFEST_FILE });
            for (const item of ['README.md', 'LICENSE', 'dist']) {
                archive.file(path.join(directory, item), { name: item });
            }
            archive.finalize();
        });
    });
    console.log(`Packaged ${manifest.id}@${manifest.version}: ${out}`);
}

async function main() {
    const [command, positional, ...rest] = process.argv.slice(2);
    const args = [positional, ...rest].filter(Boolean);
    if (!command || command === 'help' || command === '--help') return usage();
    if (command === 'init') return init(positional || 'my-extension', rest);
    const directory = positional || '.';
    if (command === 'validate') {
        const manifest = await readManifest(directory);
        console.log(`Valid manifest: ${manifest.id}@${manifest.version} (API ${manifest.apiVersion})`);
        return;
    }
    if (command === 'pack') return pack(directory, option(rest, '--out', undefined));
    usage();
    process.exitCode = 2;
}

main().catch((error) => {
    console.error('heady-ext:', error.message);
    process.exitCode = 1;
});
