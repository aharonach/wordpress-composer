# Herd WordPress Boilerplate

This repository uses Composer to manage WordPress in Laravel Herd. Keep your custom theme and plugin source in `src/`, and let Composer sync those folders into `public/wp-content` as symlinks (or copies if symlinks are unavailable).

## Recommended local folder layout
In Herd, point the site document root at the repo's `public/` directory. The project layout looks like this:

```text
~/Herd/my-site.test/
├── .env.example
├── .gitignore
├── README.md
├── composer.json
├── composer.lock
├── setup.sh
├── src/
│   ├── plugins/
│   │   └── custom-plugin/
│   │       └── custom-plugin.php
│   └── themes/
│       └── custom-theme/
│           ├── functions.php
│           ├── index.php
│           └── style.css
├── public/
│   ├── index.php
│   ├── wp-config.php
│   ├── wp-content/
│   │   ├── plugins/
│   │   │   ├── custom-plugin -> ../../../src/plugins/custom-plugin
│   │   │   ├── classic-editor/
│   │   │   ├── wordpress-seo/
│   │   │   └── wp-mail-smtp/
│   │   └── themes/
│   │       ├── custom-theme -> ../../../src/themes/custom-theme
│   │       └── twentytwentyfive/
│   ├── wp-admin/
│   ├── wp-includes/
│   └── ... WordPress core files
└── .env
```

The local site URL in Herd is usually something like:

- http://my-site.test
- https://my-site.test

If Herd uses a separate folder for the web root, set that folder to `public/` instead of the repo root.

## Quick start
1. Install Laravel Herd and ensure `.test` domains are enabled.
2. Clone this repo into your Herd project directory, for example:
   - macOS: `~/Herd/my-site.test`
   - Windows: `C:\Users\you\Herd\my-site.test`
3. Copy the environment template:
   ```bash
   cp .env.example .env
   ```
4. Edit `.env` with your local database values and local URL.
5. Install Composer dependencies:
   ```bash
   composer install
   ```
6. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```
7. Run the bootstrap script:
   ```bash
   ./setup.sh
   ```
8. Visit `http://my-site.test/wp-admin` and log in with the admin credentials from `.env`.

## Source-managed custom code
This project keeps the source of truth for custom features in `src/`:

- `src/themes/custom-theme`
- `src/plugins/custom-plugin`

These are included via Composer's local path repositories, so they are installed and symlinked into the WordPress runtime without needing a separate sync script.

Your custom plugin and theme packages can live in `src/` and be required from Composer directly, while WordPress reads them through the symlinked path repository layout.

## Database and local config
This repo intentionally avoids committing a real `public/wp-config.php`. Instead, use a local `.env` file and let `wp config create` generate the config file for you during setup.

A typical `.env` config looks like:

```dotenv
DB_NAME=wordpress
DB_USER=root
DB_PASSWORD=root
DB_HOST=127.0.0.1
WP_HOME=http://wordpress.test
WP_SITEURL=http://wordpress.test
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=Password123!
WP_ADMIN_EMAIL=admin@example.test
```

## Plugin automation
This project uses Composer for all third-party plugin management.

Add a plugin with:

```bash
composer require wpackagist-plugin/woocommerce
```

Or install the recommended defaults already listed in `composer.json`:

```bash
composer require wpackagist-plugin/classic-editor
composer require wpackagist-plugin/wp-mail-smtp
composer require wpackagist-plugin/wordpress-seo
```

Then run:

```bash
./setup.sh
```

This keeps WordPress core and third-party plugins in sync with Composer, while custom code remains under `src/`.

## Git strategy
Keep custom source code in Git:

- `src/themes/custom-theme`
- `src/plugins/custom-plugin`

Ignore generated or external code:

- `public/wp-config.php`
- `public/wp-content/`
- `vendor/`
- `public/wp-content/uploads/`

## Notes
- Herd handles PHP, MySQL/MariaDB, and domain routing, so no Docker or custom build stack is required.
- The WordPress docroot is `public/`, which is the Composer-safe way to keep WordPress in a project directory without installing it in the repo root.
- Your site in Herd should point to the `public/` folder if you want the domain to resolve cleanly.
