export const MANIFEST_FILE = 'heady-extension.json';
export const SDK_API_VERSION = '1';

const ID_PATTERN = /^[a-z][a-z0-9-]{2,63}$/;
const SEMVER_PATTERN = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;

export function validateManifest(value) {
    const errors = [];
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
        return { valid: false, errors: ['Manifest must be a JSON object.'] };
    }

    if (typeof value.id !== 'string' || !ID_PATTERN.test(value.id)) {
        errors.push('id must be 3–64 lowercase letters, numbers, or hyphens and start with a letter.');
    }
    for (const field of ['name', 'version', 'description', 'apiVersion']) {
        if (typeof value[field] !== 'string' || value[field].trim() === '') {
            errors.push(field + ' is required and must be a non-empty string.');
        }
    }
    if (typeof value.version === 'string' && !SEMVER_PATTERN.test(value.version)) {
        errors.push('version must be a semantic version such as 1.2.3.');
    }
    if (typeof value.apiVersion === 'string' && value.apiVersion !== SDK_API_VERSION) {
        errors.push('Unsupported apiVersion ' + value.apiVersion + '; this SDK supports ' + SDK_API_VERSION + '.');
    }
    for (const field of ['name', 'description', 'author', 'homepage', 'license', 'entry']) {
        if (value[field] !== undefined && typeof value[field] !== 'string') {
            errors.push(field + ' must be a string when provided.');
        }
    }
    if (value.permissions !== undefined && (!Array.isArray(value.permissions) ||
        value.permissions.some((permission) => typeof permission !== 'string' || !/^[a-z][a-z0-9:._-]{1,63}$/.test(permission)))) {
        errors.push('permissions must be an array of permission identifiers.');
    }
    if (typeof value.entry === 'string' && (value.entry.startsWith('/') || value.entry.includes('\\\\') ||
        value.entry.split('/').some((part) => part === '..' || part === '.'))) {
        errors.push('entry must be a safe relative path.');
    }

    return { valid: errors.length === 0, errors };
}
