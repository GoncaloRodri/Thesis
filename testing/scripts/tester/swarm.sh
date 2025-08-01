#!/bin/bash

declare -a nodes=("authority" "relay1" "relay2" "exit1" "client")
declare -a machines

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABS_DIR="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"
source "${SCRIPT_DIR}/src/config.sh"

MANAGER_IP=127.0.0.1

docker swarm leave --force

JOIN_CMD=$(docker swarm init --advertise-addr $MANAGER_IP | grep "join --token")

# TODO: JOIN WORKER NODES
for node in "${nodes[@]}"; do
  ssh ${node} "${JOIN_CMD}"
done

docker node ls

# TODO: NAME NODES TO FUNCTIONALITY

docker node update --label-add node=authority authority
docker node update --label-add node=relay1 relay1
docker node update --label-add node=relay2 relay2
docker node update --label-add node=exit1 exit1
docker node update --label-add node=client client

