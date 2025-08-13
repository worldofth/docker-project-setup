# 🔍 Solr 5.5.5 Search Engine Setup

A legacy Solr 5.5.5 service for older website compatibility that provides full-text search capabilities with custom schema support.

## 🚀 Quick Start

### 1. Start Solr Service

```bash
# Using Make commands (recommended)
make solr555-up

# Or using Docker Compose directly
docker compose -f docker/docker-compose.solr-555.yml up -d
```

### 2. Add Custom Schema (Optional)

```bash
# Copy your custom schema.xml to the data directory
cp schema.xml docker/solr555/data/
```

### 3. Configure Core

```bash
# Using Make command (recommended)
make solr555-setup

# Or run setup script directly
cd docker/solr555
./setup.sh
```

### 4. Access Solr

- **Admin Interface**: `http://localhost:8984/solr/`
- **Default Core**: `http://localhost:8984/solr/harbour/`

## 🔧 Configuration

### Environment Variables

Configure in your `.env` file:

```bash
# Solr 5.5.5 specific settings
SOLR_555_PORT=8984                    # External access port
SOLR_555_ENABLE_CORS=true             # Enable CORS for browser access
SOLR_555_CORE_NAME=harbour            # Default core name
```

### Custom Schema

**Important**: Place your custom `schema.xml` file in `docker/solr555/data/` **before** running the setup command to use custom field definitions and configurations.

```bash
# Copy your schema file first
cp schema.xml docker/solr555/data/

# Then run setup
make solr555-setup
```

## 📁 Directory Structure

```
docker/solr555/
├── Dockerfile                   # Custom Ubuntu 18.04 + Java 8 image
├── setup.sh                    # Core configuration script
├── data/                       # Custom schema and config files
│   └── schema.xml              # Custom Solr schema (optional)
├── solr-data/                  # Persistent Solr data storage
├── bin/                        # Custom startup scripts
│   ├── docker-run.sh
│   └── docker-stop.sh
└── docker-compose.solr-555.yml # Service definition
```

## 📋 Available Make Commands

### Service Management
```bash
make solr555-up           # Start Solr 5.5.5 service
make solr555-down         # Stop Solr 5.5.5 service
make solr555-restart      # Restart Solr 5.5.5 service
make solr555-status       # Show container status
make solr555-logs         # Show real-time logs
```

### Core and Configuration
```bash
make solr555-setup        # Create core and configure schema
make solr555-cli          # Access container shell
```

### Combined Operations
```bash
make up-with-solr555      # Start main stack + Solr 5.5.5
make down-all             # Stop main stack + all Solr services
```

### Maintenance
```bash
make solr555-rebuild      # Rebuild containers (after Dockerfile changes)
make solr555-clean        # Remove containers and volumes
```

## 🛠️ Core Management

### Create/Recreate Core

The setup script automatically:
1. Checks for existing core and deletes if found
2. Creates new core with basic configuration
3. Switches to ClassicIndexSchemaFactory
4. Applies custom schema if available
5. Restarts Solr to apply changes

```bash
# Using Make command (recommended)
make solr555-setup

# Manual setup script execution
cd docker/solr555
./setup.sh

# Or specify custom core name
SOLR_555_CORE_NAME=mycustomcore make solr555-setup
```

### Manual Core Operations

```bash
# Access Solr container
make solr555-cli
# Or directly: docker compose -f docker/docker-compose.solr-555.yml exec solr bash

# Create core manually
/home/solr/solr-5.5.5/bin/solr create -c mycore -d basic_configs

# Delete core
/home/solr/solr-5.5.5/bin/solr delete -c mycore

# Check status
/home/solr/solr-5.5.5/bin/solr status
```

## 🔗 Network Integration

The Solr service connects to the main project network, allowing other containers to access it via:

- **Internal URL**: `http://solr:8983/solr/`
- **Core URL**: `http://solr:8983/solr/harbour/`

## 🔄 Data Persistence

- **Solr Data**: Stored in `docker/solr555/solr-data/`
- **Custom Files**: Place in `docker/solr555/data/`
- **Configuration**: Persists across container restarts

## 🐛 Troubleshooting

### Port Conflicts

If port 8984 is in use:

```bash
# Edit .env
SOLR_555_PORT=8985

# Restart service
docker compose -f docker/docker-compose.solr-555.yml down
docker compose -f docker/docker-compose.solr-555.yml up -d
```

### Schema Issues

If custom schema isn't applying:

1. Ensure `schema.xml` is in `docker/solr555/data/`
2. Run setup script to recreate core: `./setup.sh`
3. Check logs: `docker compose -f docker/docker-compose.solr-555.yml logs solr`

### Core Access Problems

```bash
# Check if core exists
docker compose -f docker/docker-compose.solr-555.yml exec solr /home/solr/solr-5.5.5/bin/solr status

# Restart Solr service
docker compose -f docker/docker-compose.solr-555.yml restart solr
```

## 💡 Usage Tips

- **Use unique core names** for different projects
- **Backup solr-data/** before major changes
- **Custom schemas** should be placed in `data/` directory before running setup
- **CORS is enabled** by default for browser-based applications
- **Java 8 and Ubuntu 18.04** are used for Solr 5.5.5 compatibility

## 📊 Monitoring

### Check Service Status

```bash
# Container status (using Make)
make solr555-status

# Solr service status
make solr555-cli
/home/solr/solr-5.5.5/bin/solr status

# View logs (using Make)
make solr555-logs
```

### Access Logs

```bash
# Real-time logs (using Make)
make solr555-logs

# Direct Docker commands
docker compose -f docker/docker-compose.solr-555.yml logs -f solr
docker logs myproject-solr555
```