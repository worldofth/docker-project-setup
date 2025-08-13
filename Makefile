# =============================================================================
# Docker PHP Development Environment - Makefile
# =============================================================================
#
# This Makefile provides a simple command interface for managing the Docker
# development environment. All commands are designed to be run from the
# project root directory.
#
# QUICK START:
#   make setup    # Initial project setup
#   make up       # Start all services
#   make logs     # Monitor startup
#
# DAILY WORKFLOW:
#   make status   # Check what's running
#   make cli      # Access PHP container
#   make db-cli   # Access database
#
# For complete command list, run: make help
#
# =============================================================================

# Declare all phony targets to avoid conflicts with files
.PHONY: help setup up down restart status logs clean rebuild certs
.PHONY: db-cli db-dump db-import db-reset fix-perms cli
.PHONY: composer php artisan drush artisan-migrate artisan-clear composer-install
.PHONY: solr555-up solr555-down solr555-restart solr555-status solr555-logs solr555-setup solr555-cli solr555-rebuild solr555-clean
.PHONY: up-with-solr555 down-all
.DEFAULT_GOAL := help

# =============================================================================
# CONFIGURATION AND DETECTION
# =============================================================================

# Colors for enhanced terminal output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
BOLD := \033[1m
NC := \033[0m # No Color

# Auto-detect available frameworks and tools in current project
ARTISAN_EXISTS := $(shell test -f artisan && echo "yes" || echo "no")
DRUSH_EXISTS := $(shell test -f vendor/bin/drush -o -f drush && echo "yes" || echo "no")
COMPOSER_EXISTS := $(shell test -f composer.json && echo "yes" || echo "no")

# =============================================================================
# HELP SYSTEM
# =============================================================================

help: ## Show this help message with organized command categories
	@echo "$(BOLD)$(BLUE)🐳 Docker PHP Development Environment$(NC)"
	@echo "$(BLUE)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(BOLD)$(GREEN)📋 QUICK START GUIDE:$(NC)"
	@echo "  $(YELLOW)1.$(NC) make setup          # First-time project setup"
	@echo "  $(YELLOW)2.$(NC) make up             # Start all services"
	@echo "  $(YELLOW)3.$(NC) Visit: http://localhost:8014 (or your HTTP_PORT)"
	@echo "  $(YELLOW)4.$(NC) make certs          # Optional: Generate SSL certificates"
	@echo ""
	@echo "$(BOLD)$(GREEN)🚀 ENVIRONMENT MANAGEMENT:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(setup|up|down|restart|status|logs|clean|rebuild)"
	@echo ""
	@echo "$(BOLD)$(GREEN)🗄️ DATABASE OPERATIONS:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "db-"
	@echo ""
	@echo "$(BOLD)$(GREEN)⚙️ DEVELOPMENT TOOLS:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(composer|php|artisan|drush|cli)"
	@echo ""
	@echo "$(BOLD)$(GREEN)🔍 SOLR SEARCH ENGINE (5.5.5):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "solr555"
	@echo ""
	@echo "$(BOLD)$(GREEN)🔧 UTILITIES:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(certs|fix-perms)"
	@echo ""
	@echo "$(BOLD)$(GREEN)💡 COMMON USAGE EXAMPLES:$(NC)"
	@echo "  $(BLUE)Framework Commands:$(NC)"
	@echo "    make artisan cache:clear"
	@echo "    make artisan migrate:fresh --seed"
	@echo "    make drush status"
	@echo ""
	@echo "  $(BLUE)Package Management:$(NC)"
	@echo "    make composer install"
	@echo "    make composer require laravel/telescope"
	@echo "    make composer update"
	@echo ""
	@echo "  $(BLUE)Database Operations:$(NC)"
	@echo "    make db-dump > backup.sql"
	@echo "    make db-import < backup.sql"
	@echo "    make db-reset"
	@echo ""
	@echo "  $(BLUE)Debugging & Access:$(NC)"
	@echo "    make cli             # Interactive PHP shell"
	@echo "    make php -v          # Check PHP version"
	@echo "    make logs-mysql      # MySQL container logs"
	@echo ""
	@echo "$(YELLOW)💡 TIP:$(NC) Run 'make status' anytime to check what containers are running"

# =============================================================================
# ENVIRONMENT MANAGEMENT COMMANDS
# =============================================================================
# Commands for starting, stopping, and managing the Docker environment

setup: ## Initial project setup (copy .env, create directories)
	@echo "$(YELLOW)Setting up project...$(NC)"
	@if [ ! -f docker/.env ]; then \
		cp docker/.env.example docker/.env; \
		echo "$(GREEN)✓$(NC) Created docker/.env from example"; \
		echo "$(RED)⚠$(NC)  Please edit docker/.env and set PROJECT_NAME"; \
	else \
		echo "$(YELLOW)⚠$(NC)  docker/.env already exists"; \
	fi
	@mkdir -p docker/mysql-data docker/certs docker/dumps
	@echo "$(GREEN)✓$(NC) Created necessary directories"
	@echo "$(GREEN)✓$(NC) Setup complete! Edit docker/.env then run 'make up'"

up: ## Start all services
	@echo "$(YELLOW)Ensuring SSL certificates exist...$(NC)"
	@./docker/scripts/ensure-certs.sh
	@echo "$(YELLOW)Starting services...$(NC)"
	@cd docker && docker-compose up -d
	@echo "$(GREEN)✓$(NC) Services started"
	@make status

down: ## Stop all services
	@echo "$(YELLOW)Stopping services...$(NC)"
	@cd docker && docker-compose down
	@echo "$(GREEN)✓$(NC) Services stopped"

restart: ## Restart all services
	@echo "$(YELLOW)Restarting services...$(NC)"
	@cd docker && docker-compose restart
	@echo "$(GREEN)✓$(NC) Services restarted"

status: ## Show container status
	@cd docker && docker-compose ps

logs: ## Show all logs
	@cd docker && docker-compose logs -f

logs-php: ## Show PHP logs
	@cd docker && docker-compose logs -f php-fpm php-cli

logs-nginx: ## Show Nginx logs
	@cd docker && docker-compose logs -f nginx

logs-mysql: ## Show MySQL logs
	@cd docker && docker-compose logs -f mysql

clean: ## Remove containers and clean up
	@echo "$(YELLOW)Cleaning up...$(NC)"
	@cd docker && docker-compose down -v --remove-orphans
	@cd docker && docker-compose rm -f
	@echo "$(GREEN)✓$(NC) Cleanup complete"

rebuild: ## Rebuild containers (after Dockerfile changes)
	@echo "$(YELLOW)Rebuilding containers...$(NC)"
	@cd docker && docker-compose build --no-cache
	@echo "$(GREEN)✓$(NC) Rebuild complete"

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================
# Commands for managing MySQL database, backups, and data import/export

# Database operations
db-cli: ## Access MySQL CLI
	@cd docker && docker-compose exec mysql mysql -uroot -p$$(grep -v '^#' .env | grep MYSQL_ROOT_PASSWORD | cut -d '=' -f2)

db-dump: ## Export database to docker/dumps/
	@echo "$(YELLOW)Creating database dump...$(NC)"
	@mkdir -p docker/dumps
	@cd docker && docker-compose exec mysql mysqldump -uroot -p$$(grep -v '^#' .env | grep MYSQL_ROOT_PASSWORD | cut -d '=' -f2) $$(grep -v '^#' .env | grep MYSQL_DATABASE | cut -d '=' -f2) > dumps/dump_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✓$(NC) Database dumped to docker/dumps/"

db-import: ## Import SQL from stdin (usage: make db-import < backup.sql)
	@echo "$(YELLOW)Importing SQL from stdin...$(NC)"
	@cd docker && docker-compose exec -T mysql mysql -uroot -p$$(grep -v '^#' .env | grep MYSQL_ROOT_PASSWORD | cut -d '=' -f2) $$(grep -v '^#' .env | grep MYSQL_DATABASE | cut -d '=' -f2)
	@echo "$(GREEN)✓$(NC) Database imported"

db-reset: ## Drop and recreate database
	@echo "$(YELLOW)Resetting database...$(NC)"
	@cd docker && docker-compose exec mysql mysql -uroot -p$$(grep -v '^#' .env | grep MYSQL_ROOT_PASSWORD | cut -d '=' -f2) -e "DROP DATABASE IF EXISTS $$(grep -v '^#' .env | grep MYSQL_DATABASE | cut -d '=' -f2); CREATE DATABASE $$(grep -v '^#' .env | grep MYSQL_DATABASE | cut -d '=' -f2);"
	@echo "$(GREEN)✓$(NC) Database reset"

# =============================================================================
# DEVELOPMENT TOOLS & COMMANDS
# =============================================================================
# PHP, Composer, and framework-specific commands (Laravel, Drupal, etc.)

# PHP/Application commands
composer: ## Run composer commands (usage: make composer install)
ifeq ($(COMPOSER_EXISTS),yes)
	@cd docker && docker-compose exec php-cli composer $(filter-out $@,$(MAKECMDGOALS))
else
	@echo "$(RED)❌$(NC) composer.json not found"
endif

php: ## Run PHP commands (usage: make php -v)
	@cd docker && docker-compose exec php-cli php $(filter-out $@,$(MAKECMDGOALS))

artisan: ## Run Laravel Artisan commands (usage: make artisan cache:clear)
ifeq ($(ARTISAN_EXISTS),yes)
	@cd docker && docker-compose exec php-cli php artisan $(filter-out $@,$(MAKECMDGOALS))
else
	@echo "$(RED)❌$(NC) artisan not found - this doesn't appear to be a Laravel project"
endif

drush: ## Run Drupal Drush commands (usage: make drush status)
ifeq ($(DRUSH_EXISTS),yes)
	@cd docker && docker-compose exec php-cli ./vendor/bin/drush $(filter-out $@,$(MAKECMDGOALS))
else
	@echo "$(RED)❌$(NC) drush not found - install with 'make composer require drush/drush'"
endif

cli: ## Interactive shell in PHP CLI container
	@cd docker && docker-compose exec php-cli bash

# Common shortcuts
artisan-migrate: ## Run Laravel migrations
	@make artisan migrate

artisan-clear: ## Clear Laravel caches
	@make artisan cache:clear

composer-install: ## Install composer dependencies
	@make composer install

# =============================================================================
# UTILITIES & MAINTENANCE
# =============================================================================
# SSL certificates, permissions, and system maintenance commands

# Utilities
certs: ## Generate trusted SSL certificates with mkcert
	@echo "$(YELLOW)Generating trusted SSL certificates with mkcert...$(NC)"
	@./docker/scripts/generate-certs.sh
	@echo "$(GREEN)✓$(NC) Trusted certificates generated"

install-ca-macos: ## Install CA certificate to macOS keychain (manual method)
	@echo "$(YELLOW)Installing CA certificate to macOS keychain...$(NC)"
	@if [ ! -f ~/local-cert-authority/rootCA.pem ]; then \
		echo "$(RED)Error:$(NC) CA certificate not found at ~/local-cert-authority/rootCA.pem"; \
		echo "Please run 'make certs' first to generate the CA"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Adding CA to system keychain (requires admin password)...$(NC)"
	@sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ~/local-cert-authority/rootCA.pem
	@echo "$(GREEN)✓$(NC) CA certificate installed successfully"
	@echo "$(GREEN)✓$(NC) All mkcert certificates will now be trusted by browsers"

remove-ca-macos: ## Remove CA certificate from macOS keychain
	@echo "$(YELLOW)Removing CA certificate from macOS keychain...$(NC)"
	@sudo security delete-certificate -c "mkcert" /Library/Keychains/System.keychain || true
	@echo "$(GREEN)✓$(NC) CA certificate removed (if it existed)"

verify-ca-macos: ## Verify CA is installed in macOS keychain
	@echo "$(YELLOW)Checking for CA certificate in keychain...$(NC)"
	@if security find-certificate -a -c "mkcert" /Library/Keychains/System.keychain > /dev/null 2>&1; then \
		echo "$(GREEN)✓$(NC) CA certificate is installed"; \
		security find-certificate -p -c "mkcert" /Library/Keychains/System.keychain | openssl x509 -noout -subject; \
	else \
		echo "$(RED)❌$(NC) CA certificate not found in keychain"; \
	fi

fix-perms: ## Fix file permissions
	@echo "$(YELLOW)Fixing file permissions...$(NC)"
	@sudo chown -R $(shell id -u):$(shell id -g) .
	@echo "$(GREEN)✓$(NC) Permissions fixed"

# =============================================================================
# SOLR 5.5.5 SEARCH ENGINE COMMANDS
# =============================================================================
# Commands for managing Solr 5.5.5 service for legacy website compatibility

solr555-up: ## Start Solr 5.5.5 service
	@echo "$(YELLOW)Starting Solr 5.5.5 service...$(NC)"
	@cd docker && docker-compose -f docker-compose.solr-555.yml up -d
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 started"

solr555-down: ## Stop Solr 5.5.5 service
	@echo "$(YELLOW)Stopping Solr 5.5.5 service...$(NC)"
	@cd docker && docker-compose -f docker-compose.solr-555.yml down
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 stopped"

solr555-restart: ## Restart Solr 5.5.5 service
	@echo "$(YELLOW)Restarting Solr 5.5.5 service...$(NC)"
	@cd docker && docker-compose -f docker-compose.solr-555.yml restart
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 restarted"

solr555-status: ## Show Solr 5.5.5 container status
	@cd docker && docker-compose -f docker-compose.solr-555.yml ps

solr555-logs: ## Show Solr 5.5.5 logs
	@cd docker && docker-compose -f docker-compose.solr-555.yml logs -f solr

solr555-setup: ## Create Solr core and configure schema
	@echo "$(YELLOW)Setting up Solr 5.5.5 core and schema...$(NC)"
	@cd docker && ./solr555/setup.sh
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 core configured"

solr555-cli: ## Access Solr 5.5.5 container shell
	@cd docker && docker-compose -f docker-compose.solr-555.yml exec solr bash

solr555-rebuild: ## Rebuild Solr 5.5.5 containers (after Dockerfile changes)
	@echo "$(YELLOW)Rebuilding Solr 5.5.5 containers...$(NC)"
	@cd docker && docker-compose -f docker-compose.solr-555.yml build --no-cache
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 rebuild complete"

solr555-clean: ## Remove Solr 5.5.5 containers and volumes
	@echo "$(YELLOW)Cleaning up Solr 5.5.5...$(NC)"
	@cd docker && docker-compose -f docker-compose.solr-555.yml down -v --remove-orphans
	@echo "$(GREEN)✓$(NC) Solr 5.5.5 cleanup complete"

up-with-solr555: ## Start main stack + Solr 5.5.5
	@echo "$(YELLOW)Starting main stack with Solr 5.5.5...$(NC)"
	@make up
	@make solr555-up
	@echo "$(GREEN)✓$(NC) All services started with Solr 5.5.5"

down-all: ## Stop main stack + all Solr services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@make down
	@make solr555-down
	@echo "$(GREEN)✓$(NC) All services stopped"


# =============================================================================
# MAKEFILE INTERNAL FUNCTIONS
# =============================================================================

# Prevent Make from treating command arguments as targets
# This allows commands like "make artisan cache:clear" to work properly
%:
	@:
