export { MANIFEST_FILE, SDK_API_VERSION, validateManifest } from './manifest.js';

/**
 * The host runtime contract for a future sandboxed extension host.
 * Extensions should export register(context); the current panel package
 * manager does not import or execute this function.
 *
 * @typedef {Object} HeadyExtensionContext
 * @property {string} extensionId
 * @property {string} apiVersion
 * @property {{ info(message: string, data?: unknown): void; warn(message: string, data?: unknown): void; error(message: string, data?: unknown): void }} logger
 * @property {{ request<T>(method: 'GET'|'POST'|'PATCH'|'DELETE', path: string, body?: unknown): Promise<T> }} api
 */

/**
 * @typedef {Object} HeadyExtensionDefinition
 * @property {string} id
 * @property {string} name
 * @property {string} version
 * @property {(context: HeadyExtensionContext) => void | Promise<void>} activate
 * @property {() => void | Promise<void>} [deactivate
 */

/**
 * Example contract only; it is not a host implementation or a security sandbox.
 */
export function defineExtension(definition) {
    if (!definition || typeof definition !== 'object') {
        throw new TypeError('Extension definition must be an object.');
    }
    for (const key of ['id', 'name', 'version']) {
        if (typeof definition[key] !== 'string' || definition[key].trim() === '') {
            throw new TypeError('Extension definition requires ' + key + '.');
        }
    }
    if (typeof definition.activate !== 'function') {
        throw new TypeError('Extension definition requires an activate(context) function.');
    }
    return Object.freeze({ ...definition });
}
