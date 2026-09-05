# WordPress Composer Boilerplate

This repository uses Composer to manage WordPress with a clean separation of concerns. It is stack-agnostic and works out of the box with standard **Apache** environments (VirtualHosts, MAMP, XAMPP, LAMP), **Laravel Herd**, or any PHP/MySQL local setup.

Your custom themes and plugins live in `src/` as local Composer path packages, while WordPress core and third-party plugins are installed in the `public/` web root.

## Recommended local folder layout
Set your Apache `DocumentRoot` (or Herd site root) to the repo's `public/` directory:

```text
my-project/
├── .env.example
├── .gitignore
├── README.md
├── composer.json
├── composer.lock
├── setup.sh
├── src/
│   ├── plugins/
│   │   └── custom-plugin/
│   │       ├── composer.json
│   │       └── custom-plugin.php
│   └── themes/
│       └── custom-theme/
│           ├── composer.json
│           ├── functions.php
│           ├── index.php
│           └── style.css
├── public/
│   ├── index.php
│   ├── wp-config.php
│   ├── wp-content/
│   │   ├── plugins/
│   │   │   ├── custom-plugin -> ../../../src/plugins/custom-plugin
│   │   │   └── seo-by-rank-math/
│   │   └── themes/
│   │       └── custom-theme -> ../../../src/themes/custom-theme
│   ├── wp-admin/
│   ├── wp-includes/
│   └── ... WordPress core files
└── .env
```

### Apache VirtualHost example
```apache
<VirtualHost *:80>
    ServerName my-site.local
    DocumentRoot "/path/to/my-project/public"

    <Directory "/path/to/my-project/public">
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```
> **Note for Apache:** Ensure `FollowSymLinks` (or `SymLinksIfOwnerMatch`) is enabled in your Directory configuration so Apache can follow the symlinks into `src/`.

### Laravel Herd / Valet
If using Laravel Herd or Valet, simply park or link the project directory and configure the site to use the `public` subdirectory as the document root.

## Quick start
1. Clone this repository into your local web projects directory.
2. Copy the environment template:
   ```bash
   cp .env.example .env
   ```
3. Edit `.env` with your local database credentials and local site URL (e.g. `http://my-site.local` or `http://localhost`).
4. Install dependencies:
   ```bash
   composer install
   ```
5. Run the setup script to create the database, generate `wp-config.php`, and install WordPress:
   ```bash
   ./setup.sh
   ```
   *(Or run `composer run setup`)*
6. Open your site URL in the browser and log in to `/wp-admin`.

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
- Works with standard Apache installations, MAMP/XAMPP, Laravel Herd, or Valet.
- The WordPress web root is `public/`. In Apache, set `DocumentRoot` to `.../public` and ensure `Options FollowSymLinks` is enabled so symlinked plugins/themes resolve properly.
- No Docker or custom node build stacks are required.
