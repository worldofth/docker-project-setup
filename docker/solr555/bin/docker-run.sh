#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# If this scripted is run out of /usr/bin or some other system bin directory
# it should be linked to and not copied. Things like java jar files are found
# relative to the canonical path of this script.
#

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container

# IP detection.
DETECTED_IP_LIST=($(
  ip addr show | grep -e "inet[^6]" | \
    sed -e "s/.*inet[^6][^0-9]*\([0-9.]*\)[^0-9]*.*/\1/" | \
    grep -v "^127\."
))
DETECTED_IP=${DETECTED_IP_LIST[0]:-127.0.0.1}
echo "DETECTED_IP=${DETECTED_IP}"

# Set environment variables.
SOLR_PREFIX=${SOLR_PREFIX:-/opt/solr}
echo "SOLR_PREFIX=${SOLR_PREFIX}"

SOLR_HOST=${SOLR_HOST:-${DETECTED_IP}}
echo "SOLR_HOST=${SOLR_HOST}"
SOLR_PORT=${SOLR_PORT:-8983}
echo "SOLR_PORT=${SOLR_PORT}"
SOLR_SERVER_DIR=${SOLR_SERVER_DIR:-${SOLR_PREFIX}/server}
echo "SOLR_SERVER_DIR=${SOLR_SERVER_DIR}"
SOLR_HOME=${SOLR_HOME:-${SOLR_SERVER_DIR}/solr}
echo "SOLR_HOME=${SOLR_HOME}"
SOLR_HEAP_SIZE=${SOLR_HEAP_SIZE:-512m}
echo "SOLR_HEAP_SIZE=${SOLR_HEAP_SIZE}"
SOLR_ADDITIONAL_PARAMETERS=${SOLR_ADDITIONAL_PARAMETERS:-""}
echo "SOLR_ADDITIONAL_PARAMETERS=${SOLR_ADDITIONAL_PARAMETERS}"
ZK_HOST=${ZK_HOST:-""}
echo "ZK_HOST=${ZK_HOST}"
ZK_HOST_LIST=($(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\1/g' | tr -s ',' ' '))
echo "ZK_HOST_LIST=${ZK_HOST_LIST}"
ZK_ZNODE=$(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\2/g')
echo "ZK_ZNODE=${ZK_ZNODE}"

STOP_PORT=${STOP_PORT:-$(expr $SOLR_PORT - 1000)}
echo "STOP_PORT=${STOP_PORT}"

ENABLE_REMOTE_JMX_OPTS=${ENABLE_REMOTE_JMX_OPTS:-false}
echo "ENABLE_REMOTE_JMX_OPTS=${ENABLE_REMOTE_JMX_OPTS}"
RMI_PORT=${RMI_PORT:-"1$SOLR_PORT"}
echo "RMI_PORT=${RMI_PORT}"

SOLR_PID_DIR=${SOLR_PID_DIR:-${SOLR_PREFIX}/bin}
echo "SOLR_PID_DIR=${SOLR_PID_DIR}"

CORE_NAME=${CORE_NAME:-""}
echo "CORE_NAME=${CORE_NAME}"

COLLECTION_NAME=${COLLECTION_NAME:-""}
echo "COLLECTION_NAME=${COLLECTION_NAME}"
COLLECTION_CONFIG_NAME=${COLLECTION_CONFIG_NAME:-${COLLECTION_NAME}_configs}
echo "COLLECTION_CONFIG_NAME=${COLLECTION_CONFIG_NAME}"
NUM_SHARDS=${NUM_SHARDS:-1}
echo "NUM_SHARDS=${NUM_SHARDS}"
REPLICATION_FACTOR=${REPLICATION_FACTOR:-1}
echo "REPLICATION_FACTOR=${REPLICATION_FACTOR}"
MAX_SHARDS_PER_NODE=${MAX_SHARDS_PER_NODE:-1}
echo "MAX_SHARDS_PER_NODE=${MAX_SHARDS_PER_NODE}"
CLOUD_SCRIPTS_DIR=${SOLR_PREFIX}/server/scripts/cloud-scripts
echo "CLOUD_SCRIPTS_DIR=${CLOUD_SCRIPTS_DIR}"
SOLR_COLLECTIONS_API_PATH=/solr/admin/collections
echo "SOLR_COLLECTIONS_API_PATH=${SOLR_COLLECTIONS_API_PATH}"

CONFIGSET=${CONFIGSET:-data_driven_schema_configs}
echo "CONFIGSET=${CONFIGSET}"

ENABLE_CORS=${ENABLE_CORS:-false}
echo "ENABLE_CORS=${ENABLE_CORS}"
FILTER_NAME=${FILTER_NAME:-cross-origin}
echo "FILTER_NAME=${FILTER_NAME}"
FILTER_CLASS=${FILTER_CLASS:-org.eclipse.jetty.servlets.CrossOriginFilter}
echo "FILTER_CLASS=${FILTER_CLASS}"
URL_PATTERN=${URL_PATTERN:-/*}
echo "URL_PATTERN=${URL_PATTERN}"
ALLOWED_ORIGINS=${ALLOWED_ORIGINS:-*}
echo "ALLOWED_ORIGINS=${ALLOWED_ORIGINS}"
ALLOWED_METHODS=${ALLOWED_METHODS:-GET,POST,OPTIONS,DELETE,PUT,HEAD}
echo "ALLOWED_METHODS=${ALLOWED_METHODS}"
ALLOWED_HEADERS=${ALLOWED_HEADERS:-origin,content-type,accept}
echo "ALLOWED_HEADERS=${ALLOWED_HEADERS}"

SOLR_ACCESS_RETRY_COUNT=${SOLR_ACCESS_RETRY_COUNT:-10}
echo "SOLR_ACCESS_RETRY_COUNT=${SOLR_ACCESS_RETRY_COUNT}"
SOLR_ACCESS_INTERVAL=${SOLR_ACCESS_INTERVAL:-1}
echo "SOLR_ACCESS_INTERVAL=${SOLR_ACCESS_INTERVAL}"

# Start function
function start() {
  # Initialize Solr home if needed
  /home/solr/init-solr-home.sh
  
  NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

  if [ "${ENABLE_CORS}" = "true" ]; then
    echo "Enabling CORS"
    cp ${SOLR_SERVER_DIR}/etc/webdefault.xml ${SOLR_SERVER_DIR}/etc/webdefault.xml.backup
    xmlstarlet ed \
      -N x="http://java.sun.com/xml/ns/javaee" \
      -s "/x:web-app" -t elem -n "filter" \
      -s "/x:web-app/filter[last()]" -t elem -n "filter-name" -v "${FILTER_NAME}" \
      -s "/x:web-app/filter[last()]" -t elem -n "filter-class" -v "${FILTER_CLASS}" \
      -s "/x:web-app/filter[last()]" -t elem -n "init-param" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-name" -v "allowedOrigins" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-value" -v "${ALLOWED_ORIGINS}" \
      -s "/x:web-app/filter[last()]" -t elem -n "init-param" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-name" -v "allowedMethods" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-value" -v "${ALLOWED_METHODS}" \
      -s "/x:web-app/filter[last()]" -t elem -n "init-param" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-name" -v "allowedHeaders" \
      -s "/x:web-app/filter[last()]/init-param[last()]" -t elem -n "param-value" -v "${ALLOWED_HEADERS}" \
      -s "/x:web-app" -t elem -n "filter-mapping" \
      -s "/x:web-app/filter-mapping[last()]" -t elem -n "filter-name" -v "${FILTER_NAME}" \
      -s "/x:web-app/filter-mapping[last()]" -t elem -n "url-pattern" -v "${URL_PATTERN}" \
      ${SOLR_SERVER_DIR}/etc/webdefault.xml > ${SOLR_SERVER_DIR}/etc/webdefault.xml.cors
    mv ${SOLR_SERVER_DIR}/etc/webdefault.xml.cors ${SOLR_SERVER_DIR}/etc/webdefault.xml
  fi

  if [ -n "${ZK_HOST}" ]; then
    # Create a znode to ZooKeeper.
    for TMP_ZK_HOST in "${ZK_HOST_LIST[@]}"
    do
      ZK_HOST_NAME=$(echo ${TMP_ZK_HOST} | cut -d":" -f1)
      ZK_HOST_PORT=$(echo ${TMP_ZK_HOST} | cut -d":" -f2)

      MATCHED_ZNODE=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}\s+.*$")
      if [ -z "${MATCHED_ZNODE}" ]; then
        echo "Creating a znode ${ZK_ZNODE} to ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}"
        ${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd makepath ${ZK_ZNODE}

        # Wait until znode created.
        for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
        do
          MATCHED_ZNODE=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}\s+.*$")
          if [ -n "${MATCHED_ZNODE}" ]; then
            echo "A znode ${ZK_ZNODE} has been created to ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}"
            break
          fi
          sleep ${SOLR_ACCESS_INTERVAL}
        done
      else
        echo "A znode ${ZK_ZNODE} already exist in ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}"
      fi
    done

    # Start Solr in SolrCloud mode.
    echo "Starting solr in SolrCloud mode"
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -m ${SOLR_HEAP_SIZE} -d ${SOLR_SERVER_DIR} -s ${SOLR_HOME} -z ${ZK_HOST} -a "${SOLR_ADDITIONAL_PARAMETERS}"
  else
    # Start Solr standalone mode.
    echo "Starting solr in standalone mode"
    ${SOLR_PREFIX}/bin/solr start -h ${SOLR_HOST} -p ${SOLR_PORT} -m ${SOLR_HEAP_SIZE} -d ${SOLR_SERVER_DIR} -s ${SOLR_HOME} -a "${SOLR_ADDITIONAL_PARAMETERS}"
  fi

  # Get Solr process id.
  SOLR_PID=$(cat $(find ${SOLR_PID_DIR} -name solr-${SOLR_PORT}.pid -type f))
  if [ -z "${SOLR_PID}" ]; then
    SOLR_PID=$(ps auxww | grep start\.jar | grep solr.solr.home | grep -E "^.*\s-Djetty.port=${SOLR_PORT}[^0-9]{0,}.*$" | grep -v grep | awk '{print $2}')
  fi

  # Wait until Solr started.
  for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
  do
    SOLR_STATUS_JSON=$(${SOLR_PREFIX}/bin/solr status | sed -n -E "/Solr process ${SOLR_PID} running on port ${SOLR_PORT}/,/}/p" | sed -n -e "/{/,/}/p")
    if [ -n "${SOLR_STATUS_JSON}" ]; then
      echo "${SOLR_STATUS_JSON}"
      break
    fi
    sleep ${SOLR_ACCESS_INTERVAL}
  done

  if [ -n "${ZK_HOST}" ]; then
    # Wait until the node is registered to live_nodes.
    for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
    do
      SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
      LIVE_NODE_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.live_nodes[]"))
      if [[ " ${LIVE_NODE_LIST[@]} " =~ " ${NODE_NAME} " ]]; then
        echo "A node ${NODE_NAME} has been registered"
        break
      else
        echo "A node ${NODE_NAME} is not registered yet"
      fi
      sleep ${SOLR_ACCESS_INTERVAL}
    done

    # Upload configset.
    COLLECTION_CONFIG_UPLOADED="0"
    for TMP_ZK_HOST in "${ZK_HOST_LIST[@]}"
    do
      ZK_HOST_NAME=$(echo ${TMP_ZK_HOST} | cut -d":" -f1)
      ZK_HOST_PORT=$(echo ${TMP_ZK_HOST} | cut -d":" -f2)

      # Check configset.
      MATCHED_COLLECTION_CONFIG_NAME=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}/configs/${COLLECTION_CONFIG_NAME}\s+.*$")
      if [ -z "${MATCHED_COLLECTION_CONFIG_NAME}" ]; then
        echo "Uploading ${SOLR_HOME}/configsets/${CONFIGSET}/conf for config ${COLLECTION_CONFIG_NAME} to ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE}"
        ${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} -cmd upconfig -confdir ${SOLR_HOME}/configsets/${CONFIGSET}/conf/ -confname ${COLLECTION_CONFIG_NAME}

        # Wait until config uploaded.
        for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
        do
          MATCHED_COLLECTION_CONFIG_NAME=$(${CLOUD_SCRIPTS_DIR}/zkcli.sh -zkhost ${ZK_HOST_NAME}:${ZK_HOST_PORT} -cmd list | grep -E "^\s+${ZK_ZNODE}/configs/${COLLECTION_CONFIG_NAME}\s+.*$")
          if [ -n "${MATCHED_COLLECTION_CONFIG_NAME}" ]; then
            echo "Config ${COLLECTION_CONFIG_NAME} has been uploaded to ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE}"
            COLLECTION_CONFIG_UPLOADED="1"
            break
          else
            echo "Config ${COLLECTION_CONFIG_NAME} is not uploaded in ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE} yet"
          fi
          sleep ${SOLR_ACCESS_INTERVAL}
        done
      else
        echo "Config ${COLLECTION_CONFIG_NAME} already exists in ZooKeeper at ${ZK_HOST_NAME}:${ZK_HOST_PORT}${ZK_ZNODE}"
        COLLECTION_CONFIG_UPLOADED="1"
      fi
      if [ "${COLLECTION_CONFIG_UPLOADED}" = "1" ]; then
        break
      fi
    done

    # Create collection.
    SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
    COLLECTION_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections | keys[]"))
    if [[ " ${COLLECTION_NAME_LIST[@]} " =~ " ${COLLECTION_NAME} " ]]; then
      echo "A collection ${COLLECTION_NAME} already exists"
    else
      echo "Creating collection ${COLLECTION_NAME}"
      curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CREATE&name=${COLLECTION_NAME}&router.name=compositeId&numShards=${NUM_SHARDS}&replicationFactor=${REPLICATION_FACTOR}&maxShardsPerNode=${MAX_SHARDS_PER_NODE}&createNodeSet=EMPTY&collection.configName=${COLLECTION_CONFIG_NAME}&wt=json" | jq .

      # Wait until collection created
      for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
      do
        SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
        COLLECTION_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections | keys[]"))
        if [[ " ${COLLECTION_NAME_LIST[@]} " =~ " ${COLLECTION_NAME} " ]]; then
          echo "A collection ${COLLECTION_NAME} has been created"
          break
        else
          echo "A collection ${COLLECTION_NAME} has not been created yet"
        fi
        sleep ${SOLR_ACCESS_INTERVAL}        
      done
    fi

    # Find shard to add.
    SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
    ACTIVE_SHARD_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards | to_entries | .[] | select(.value.state == \"active\") | .key"))
    SHARD_NAME=${ACTIVE_SHARD_NAME_LIST[0]}
    MIN_REPLICA_COUNT=$(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${ACTIVE_SHARD_NAME_LIST[0]}.replicas | to_entries | .[] | select(.value.state == \"active\") | .key" | wc -l)
    for TMP_SHARD_NAME in "${ACTIVE_SHARD_NAME_LIST[@]}"
    do
      ACTIVE_REPLICA_COUNT=$(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${TMP_SHARD_NAME}.replicas | to_entries | .[] | select(.value.state == \"active\") | .key" | wc -l)
      if [ -z "${ACTIVE_REPLICA_COUNT}" ]; then
        ACTIVE_REPLICA_COUNT=0
      fi
      echo "${TMP_SHARD_NAME} has ${ACTIVE_REPLICA_COUNT} replica(s)"
      if [[ ${MIN_REPLICA_COUNT} -gt ${ACTIVE_REPLICA_COUNT} ]]; then
        SHARD_NAME=${TMP_SHARD_NAME}
        MIN_REPLICA_COUNT=${ACTIVE_REPLICA_COUNT}
      fi
    done
    echo "Target shard is ${SHARD_NAME}"

    # Add replica.
    echo "Adding replica ${NODE_NAME} to ${COLLECTION_NAME}/${SHARD_NAME}"
    curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=ADDREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&node=${NODE_NAME}&wt=json" | jq .
  else
    echo "Creating Solr sore"
    if [ -n "${CORE_NAME}" ]; then
      # Create Solr core.
      ${SOLR_PREFIX}/bin/solr create_core -c ${CORE_NAME} -d ${CONFIGSET}
    fi
  fi

  echo "Initialized"
}

trap "docker-stop.sh; exit 1" TERM KILL INT QUIT

# Start
start

# Start infinitive loop
while true
do
  sleep 1
done