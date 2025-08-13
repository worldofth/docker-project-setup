# 🐳 Docker PHP Development Environment

A portable, self-contained Docker development environment for PHP projects that can be dropped into any project and distributed to team members without environmental dependencies.

## 🔐 HTTPS Certificate Setup

### One-Time Certificate Authority Setup

The first time you use certificates, a shared Certificate Authority will be created:

```bash
# This happens automatically when you run make certs
# But you can also set it up manually:
brew install mkcert
mkcert -install
```

This creates a shared CA in `~/local-cert-authority/` that can be used across all your projects.

### Per-Project Certificate Generation

```bash
# Generate certificates for your project
make certs

# This creates:
# - docker/certs/myproject.test.pem
# - docker/certs/myproject.test-key.pem
```

### DNS Configuration

Ensure your dnsmasq is configured to point `*.test` to `127.0.0.1`:

```bash
# Add to your dnsmasq configuration
echo 'address=/.test/127.0.0.1' >> /opt/homebrew/etc/dnsmasq.conf
sudo brew services restart dnsmasq
```

## 📁 Project Structure

```
your-project/
├── docker/
│   ├── .env                     # Configuration (copy from .env.example)
│   ├── .env.example             # Configuration template
│   ├── docker-compose.yml       # Main orchestration
│   ├── docker-compose.override.yml.example  # Customization template
│   ├── mysql-data/              # Persistent database storage
│   ├── certs/                   # SSL certificates (generated)
│   ├── dumps/                   # Database dumps
│   ├── scripts/
│   │   ├── generate-certs.sh    # Certificate generation
│   │   └── setup.sh             # Initial setup
│   ├── php/
│   │   ├── Dockerfile.fpm       # PHP-FPM container
│   │   ├── Dockerfile.cli       # PHP CLI container
│   │   └── php.ini              # PHP configuration
│   └── nginx/
│       └── default.conf         # Nginx configuration
├── public/
│   ├── index.php                # Test file
│   └── db.php                   # Database test
├── Makefile                     # Command interface
└── README.md                    # This file
```

## 🔧 Customization

### Adding PHP Extensions

Edit `.env` to add extensions:

```bash
PHP_EXTENSIONS=pdo_mysql,zip,gd,redis,imagick,soap
```

### Custom PHP Configuration

Edit `docker/php/php.ini` to modify PHP settings:

```ini
memory_limit = 1G
upload_max_filesize = 200M
post_max_size = 200M
```

## 🐛 Troubleshooting

### Port Conflicts

If port 8014 is already in use:

```bash
# Edit .env
HTTP_PORT=8015

# Restart
make restart
```

### Permission Issues

If you encounter file permission problems:

```bash
make fix-perms
```

### Database Connection Issues

1. Check if MySQL is running: `make status`
2. Wait a moment for MySQL to fully start
3. Verify .env database settings
4. Check logs: `make logs-mysql`

### Container Build Issues

If you need to rebuild containers:

```bash
make rebuild
```

### Certificate Issues

If HTTPS isn't working:

1. Ensure mkcert is installed: `brew install mkcert`
2. Reinstall CA: `mkcert -install`
3. Regenerate certificates: `make certs`
4. Restart browser

## 🚀 Framework-Specific Setup

### Laravel

```bash
make setup
make up
make composer create-project laravel/laravel .
make artisan key:generate
make artisan migrate
```

### Existing Laravel Project

```bash
make setup
make up  
make composer install
cp .env.example .env
make artisan key:generate
make artisan migrate
```

### Drupal

```bash
make setup
make up
make composer create-project drupal/recommended-project .
make drush site:install
```

## 🤝 Team Distribution

To share this setup with team members:

1. **Commit the docker/ directory** to your project repository
2. **Include Makefile** in project root
3. **Document any project-specific settings** in your project README
4. **Team members only need**:
   ```bash
   git clone your-project
   cd your-project
   make setup
   # Edit docker/.env (set PROJECT_NAME and HTTP_PORT)
   make up
   ```

## 🔄 Updating

To update to newer versions:

1. **Backup your .env file**
2. **Update image versions** in `.env`
3. **Rebuild containers**: `make rebuild`

## 📝 License

This development environment setup is provided as-is for development use.

## 💡 Tips

- **Use unique PROJECT_NAME** for each project to avoid conflicts
- **Choose different HTTP_PORT** for each project (8014, 8015, etc.)
- **Generate certificates once** per project for HTTPS
- **Use `make help`** to see all available commands
- **Check `make status`** if something isn't working
- **Use `make logs`** to debug issues

## 🔍 Additional Services

### Solr 5.5.5 Search Engine

For legacy website compatibility, a Solr 5.5.5 service is available:

📖 **[Complete Solr 5.5.5 Documentation](./solr555.md)**

Quick start:
```bash
make solr555-up     # Start Solr service
make solr555-setup  # Configure core and schema
```

Access at: `http://localhost:8984/solr/`

## 🆘 Support

Common issues and solutions:

1. **"Port already in use"** → Change HTTP_PORT in .env
2. **"Permission denied"** → Run `make fix-perms`
3. **"Database connection failed"** → Wait for MySQL to start, check `make logs-mysql`
4. **"Certificate not trusted"** → Run `mkcert -install` and restart browser
5. **"Container won't start"** → Check `make logs` and `make status`

For more help, check the generated test files at `http://localhost:8014` after running `make up`. ✨ Features

- **🚀 Quick Setup**: Start developing in minutes
- **🔒 HTTPS Support**: Optional SSL certificates with mkcert
- **🐘 Multiple PHP Versions**: Easily switch between PHP versions
- **🗄️ MySQL 8**: With persistent data storage
- **🌐 Nginx**: Optimized web server configuration
- **📦 Composer 2**: Pre-installed in CLI container
- **🛠️ Make Commands**: Simplified command interface
- **🏗️ Framework Support**: Auto-detection for Laravel, Drupal, etc.
- **💻 Cross-Platform**: Works on ARM64 Mac, Intel Mac, Linux

## 📋 Requirements

- Docker Desktop
- Make (pre-installed on macOS/Linux)
- mkcert (optional, for HTTPS support)

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone or copy the docker/ directory to your PHP project
git clone <this-repo> my-project
cd my-project

# Run initial setup
make setup

# Edit the configuration (REQUIRED)
vim docker/.env  # Set PROJECT_NAME and HTTP_PORT
```

### 2. Start Development Environment

```bash
# Start all services
make up

# Visit your project
# HTTP:  http://localhost:8014
# HTTPS: https://myproject.test:8014 (after generating certs)
```

### 3. Optional HTTPS Setup

```bash
# Generate SSL certificates (one-time setup)
make certs

# Now visit: https://myproject.test:8014
```

## 🔧 Configuration

### Environment Variables (.env)

Copy `docker/.env.example` to `docker/.env` and configure:

```bash
# Required Settings
PROJECT_NAME=myproject        # Used for container names and domain
HTTP_PORT=8014               # Port for both HTTP and HTTPS
PHP_VERSION=8.2              # PHP version to use

# Optional Settings  
PHP_EXTENSIONS=pdo_mysql,zip,gd
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=laravel
MYSQL_USER=laravel
MYSQL_PASSWORD=laravel
```

### Image Selection

If you need different Docker images (for architecture compatibility), uncomment alternatives in `.env`:

```bash
# Default (multi-arch)
MYSQL_IMAGE=mysql:8.0

# ARM64 specific (if needed)
# MYSQL_IMAGE=arm64v8/mysql:8.0

# Alternative
# MYSQL_IMAGE=mariadb:10.11
```

## 📚 Available Commands

Run `make help` to see all available commands.

### Environment Management
```bash
make setup          # Initial project setup
make up             # Start all services  
make down           # Stop all services
make restart        # Restart all services
make status         # Show container status
make logs           # Show all logs
```

### Database Operations
```bash
make db-cli                     # Access MySQL CLI
make db-dump                    # Export database
make db-import < backup.sql     # Import SQL file
make db-reset                   # Drop and recreate database
```

### Development Tools
```bash
make composer install          # Install dependencies
make composer require pkg      # Add package
make php -v                    # Run PHP commands
make cli                       # Interactive shell

# Framework-specific (auto-detected)
make artisan migrate           # Laravel
make artisan cache:clear       # Laravel  
make drush status             # Drupal
```

### Utilities
```bash
make certs          # Generate SSL certificates
make clean          # Remove containers
make rebuild        # Rebuild containers
```

## 🌐 Access URLs

After starting with `make up`:

- **HTTP**: `http://localhost:8014`
- **HTTPS**: `https://myproject.test:8014` (requires certificates)
- **Database**: `localhost:3306` (external access)
