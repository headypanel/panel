import test from 'node:test';
import assert from 'node:assert/strict';
import { validateManifest } from '../src/manifest.js';
import { defineExtension } from '../src/index.js';

const valid = {
    id: 'hello-extension', name: 'Hello', version: '1.2.3',
    description: 'Example', apiVersion: '1', entry: 'dist/index.js', permissions: []
};

test('accepts a valid manifest', () => {
    assert.deepEqual(validateManifest(valid), { valid: true, errors: [] });
});

test('rejects unsafe ids and invalid semantic versions', () => {
    assert.equal(validateManifest({ ...valid, id: '../evil' }).valid, false);
    assert.equal(validateManifest({ ...valid, version: 'latest' }).valid, false);
});

test('rejects unsupported API versions and traversal entrypoints', () => {
    assert.equal(validateManifest({ ...valid, apiVersion: '99' }).valid, false);
    assert.equal(validateManifest({ ...valid, entry: '../outside.js' }).valid, false);
});

test('rejects non-string entrypoints without throwing', () => {\n    const result = validateManifest({ ...valid, entry: 42 });\n    assert.equal(result.valid, false);\n    assert.ok(result.errors.some((error) => error.includes('entry must be a string')));\n});\n\ntest('rejects invalid permissions', () => {
    assert.equal(validateManifest({ ...valid, permissions: ['*'] }).valid, false);
});

test('defineExtension validates its public contract', () => {
    assert.throws(() => defineExtension({ id: 'x' }), /requires name/);
    assert.equal(defineExtension({ id: 'x', name: 'X', version: '1.0.0', activate() {} }).id, 'x');
});
