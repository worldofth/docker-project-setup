.PHONY: help setup up down restart status logs clean rebuild certs
.PHONY: db-cli db-dump db-import db-reset fix-perms cli
.PHONY: composer php artisan drush artisan-migrate artisan-clear composer-install
.DEFAULT_GOAL := help

# Colors for help output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Detect framework/tools
ARTISAN_EXISTS := $(shell test -f artisan && echo "yes" || echo "no")
DRUSH_EXISTS := $(shell test -f vendor/bin/drush -o -f drush && echo "yes" || echo "no")
COMPOSER_EXISTS := $(shell test -f composer.json && echo "yes" || echo "no")

help: ## Show this help message
	@echo "$(GREEN)Available commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Environment Management:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(setup|up|down|restart|status|logs|clean|rebuild)"
	@echo ""
	@echo "$(YELLOW)Database Operations:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "db-"
	@echo ""
	@echo "$(YELLOW)Development Tools:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(composer|php|artisan|drush|cli)"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep -E "(certs|fix-perms)"
	@echo ""
	@echo "$(YELLOW)Usage Examples:$(NC)"
	@echo "  make artisan cache:clear"
	@echo "  make composer require laravel/telescope"
	@echo "  make db-import < backup.sql"
	@echo "  make php -v"

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

# Database operations
db-cli: ## Access MySQL CLI
	@cd docker && docker-compose exec mysql mysql -uroot -p$$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2)

db-dump: ## Export database to docker/dumps/
	@echo "$(YELLOW)Creating database dump...$(NC)"
	@mkdir -p docker/dumps
	@cd docker && docker-compose exec mysql mysqldump -uroot -p$$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) $$(grep MYSQL_DATABASE .env | cut -d '=' -f2) > dumps/dump_$$(date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✓$(NC) Database dumped to docker/dumps/"

db-import: ## Import SQL from stdin (usage: make db-import < backup.sql)
	@echo "$(YELLOW)Importing SQL from stdin...$(NC)"
	@cd docker && docker-compose exec -T mysql mysql -uroot -p$$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) $$(grep MYSQL_DATABASE .env | cut -d '=' -f2)
	@echo "$(GREEN)✓$(NC) Database imported"

db-reset: ## Drop and recreate database
	@echo "$(YELLOW)Resetting database...$(NC)"
	@cd docker && docker-compose exec mysql mysql -uroot -p$$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2) -e "DROP DATABASE IF EXISTS $$(grep MYSQL_DATABASE .env | cut -d '=' -f2); CREATE DATABASE $$(grep MYSQL_DATABASE .env | cut -d '=' -f2);"
	@echo "$(GREEN)✓$(NC) Database reset"

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

# Utilities
certs: ## Generate SSL certificates
	@echo "$(YELLOW)Generating SSL certificates...$(NC)"
	@./docker/scripts/generate-certs.sh
	@echo "$(GREEN)✓$(NC) Certificates generated"

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

# Prevent Make from treating arguments as targets
%:
	@: