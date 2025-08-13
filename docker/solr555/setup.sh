#!/usr/bin/env bash

# Source environment variables from .env file, excluding readonly variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -v '^UID=' | grep -v '^GID=' | xargs)
fi

# Read core name from environment variable or use default
CORE_NAME=${SOLR_555_CORE_NAME:-harbour}

echo "Configuring Solr core '$CORE_NAME'..."

# Check if core exists, if not create it
if docker compose -f docker-compose.solr-555.yml exec solr /home/solr/solr-5.5.5/bin/solr status | grep -q "$CORE_NAME"; then
    echo "Core '$CORE_NAME' already exists. Deleting it to recreate with proper schema factory..."
    docker compose -f docker-compose.solr-555.yml exec solr /home/solr/solr-5.5.5/bin/solr delete -c "$CORE_NAME"
fi

echo "Creating new core '$CORE_NAME'..."
docker compose -f docker-compose.solr-555.yml exec solr /home/solr/solr-5.5.5/bin/solr create -c "$CORE_NAME" -d basic_configs

# Switch to ClassicIndexSchemaFactory BEFORE copying custom schema
echo "Switching to ClassicIndexSchemaFactory..."
docker compose -f docker-compose.solr-555.yml exec solr sed -i '/<schemaFactory class="ManagedIndexSchemaFactory">/,/<\/schemaFactory>/c\<schemaFactory class="ClassicIndexSchemaFactory"/>' /home/solr/solr-5.5.5/server/solr/"$CORE_NAME"/conf/solrconfig.xml

# Always apply configuration (schema and solrconfig changes)
echo "Applying custom schema and configuration..."

# Copy custom schema.xml
if docker compose -f docker-compose.solr-555.yml exec solr test -f /home/solr/data/schema.xml; then
    docker compose -f docker-compose.solr-555.yml exec solr cp /home/solr/data/schema.xml /home/solr/solr-5.5.5/server/solr/"$CORE_NAME"/conf/
    echo "Custom schema.xml copied."
else
    echo "Warning: /home/solr/data/schema.xml not found. Using default schema."
fi

# Restart Solr to apply changes
echo "Restarting Solr to apply configuration changes..."
docker compose -f docker-compose.solr-555.yml exec solr /home/solr/solr-5.5.5/bin/solr restart

echo "Core '$CORE_NAME' configured successfully!"
echo "Access the core at: http://localhost:${SOLR_555_PORT:-8984}/solr/$CORE_NAME/"
