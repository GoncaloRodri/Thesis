#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABS_DIR="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"
source "${SCRIPT_DIR}/src/config.sh"

MANAGER_IP=127.0.0.1

docker swarm leave --force

docker swarm init --advertise-addr $MANAGER_IP

# TODO: JOIN WORKER NODES


