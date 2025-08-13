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
ZK_HOST=${ZK_HOST:-""}
echo "ZK_HOST=${ZK_HOST}"
ZK_HOST_LIST=($(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\1/g' | tr -s ',' ' '))
echo "ZK_HOST_LIST=${ZK_HOST_LIST}"
ZK_ZNODE=$(echo ${ZK_HOST} | sed -e 's/^\(.\{1,\}:[0-9]\{1,\}\)*\(.*\)$/\2/g')
echo "ZK_ZNODE=${ZK_ZNODE}"

SOLR_COLLECTIONS_API_PATH=/solr/admin/collections
echo "SOLR_COLLECTIONS_API_PATH=${SOLR_COLLECTIONS_API_PATH}"

SOLR_ACCESS_RETRY_COUNT=${SOLR_ACCESS_RETRY_COUNT:-10}
echo "SOLR_ACCESS_RETRY_COUNT=${SOLR_ACCESS_RETRY_COUNT}"
SOLR_ACCESS_INTERVAL=${SOLR_ACCESS_INTERVAL:-1}
echo "SOLR_ACCESS_INTERVAL=${SOLR_ACCESS_INTERVAL}"

# Stop function.
function stop() {
  NODE_NAME=${SOLR_HOST}:${SOLR_PORT}_solr

  # SolrCloud mode?
  if [ -n "${ZK_HOST}" ]; then
    # Get collection list.
    SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
    COLLECTION_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections | keys[]"))
    for COLLECTION_NAME in "${COLLECTION_NAME_LIST[@]}"
    do
      # Get shard list in a collection.
      SHARD_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards | keys[]"))
      for SHARD_NAME in "${SHARD_NAME_LIST[@]}"
      do
        # Get replica list in a shard.
        REPLICA_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.node_name == \"${NODE_NAME}\") | .key"))
        if [ -n "${REPLICA_NAME_LIST[@]}" ]; then
          for REPLICA_NAME in "${REPLICA_NAME_LIST[@]}"
          do
            # Delete replica.
            echo "Deleting replica ${REPLICA_NAME}(${NODE_NAME}) from ${COLLECTION_NAME}/${SHARD_NAME}"
            curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=DELETEREPLICA&collection=${COLLECTION_NAME}&shard=${SHARD_NAME}&replica=${REPLICA_NAME}&wt=json" | jq .
          done
        fi
      done
    done

    # Wait until replica deleted.
    for i in `seq ${SOLR_ACCESS_RETRY_COUNT}`
    do
      SOLR_CLUSTER_STATUS_JSON=$(curl -s "http://${SOLR_HOST}:${SOLR_PORT}${SOLR_COLLECTIONS_API_PATH}?action=CLUSTERSTATUS&wt=json")
      REPLICA_NAME_LIST=($(echo ${SOLR_CLUSTER_STATUS_JSON} | jq -r ".cluster.collections.${COLLECTION_NAME}.shards.${SHARD_NAME}.replicas | to_entries | .[] | select(.value.node_name == \"${NODE_NAME}\") | .key"))
      if [ -z "${REPLICA_NAME_LIST[@]}" ]; then
        echo "${NODE_NAME} has been deleted"
        break
      else
        echo "A node ${NODE_NAME} is not deleted yet"
      fi
      sleep ${SOLR_ACCESS_INTERVAL}
    done
  fi
  
  ${SOLR_PREFIX}/bin/solr stop -p ${SOLR_PORT}

  echo "Deleted"
}

# Stop
stop