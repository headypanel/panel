# HeadyPanel release installer

Each tagged release generates a version-specific `headypanel-install.sh` asset alongside `panel.tar.gz`. The generated installer downloads the archive for that exact release.

## Supported operating systems

- Debian 12 (PHP 8.2)
- Ubuntu 24.04 (PHP 8.3)

Other distributions and PHP versions are rejected rather than installed with an unsupported runtime.

## Install

1. Create a clean Debian 12 or Ubuntu 24.04 server.
2. Open the HeadyPanel GitHub Releases page and download `headypanel-install.sh` from the release you intend to install.
3. Run it interactively as root:

   ```bash
   chmod +x headypanel-install.sh
   sudo ./headypanel-install.sh
   ```

4. Enter the install directory, public host name, and optionally an email address for Let's Encrypt.

The installer installs PHP and required extensions, Nginx, MariaDB, Redis, Composer, the panel release archive, a restricted local database account, the Laravel dependencies and migrations, Nginx configuration, a queue worker, and the Laravel scheduler. It prompts to create the first panel administrator.

If an email is supplied, the host must already resolve to this server and inbound TCP port 80 must be reachable for Let's Encrypt. Without an email, the panel is configured for HTTP only; place it behind a trusted TLS reverse proxy before exposing it publicly.

## Important notes

- Use a fresh server or an empty install directory. This installer is not an upgrade or migration tool.
- Back up existing panel data before making changes. The installer is intended for a new installation.
- The generated database password is displayed once at the end. Store it securely.
- Review the installer before running it on production infrastructure.
- Releases are created as drafts by CI. The installer download URL becomes usable after the release is published.
