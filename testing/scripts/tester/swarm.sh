#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"

COMPOSE_FILE="${SCRIPT_DIR}/stack.docker-compose.yml"

AUTHORITY_IP="10.5.0.1"
AUTHORITY_SSH="root@${AUTHORITY_IP}"

RELAYS=(
    "10.5.0.2"
    "10.5.0.3"
    "10.5.0.4"
    "10.5.0.5"
)

log_info "Starting Swarm Experiment..."
log_info "Setting up Swarm Network..."

docker network rm swarm

docker network create \
    --driver overlay \
    --opt encrypted \
    --attachable \
    swarm

log_success "Swarm Network Setup Completed!"

log_info "Pulling Docker Images for Swarm Nodes..."
docker buildx build -t gugarodri/dptor_node:latest -f "${SCRIPT_DIR}"/testing/docker/node.Dockerfile "${SCRIPT_DIR}"/

docker push gugarodri/dptor_node:latest

log_info "Initializing Swarm on Authority Node..."

TOKEN=$(ssh "${AUTHORITY_SSH}" "docker swarm init --advertise-addr ${AUTHORITY_IP}")

log_info "Swarm Initialized with Token: ${TOKEN}"

for relay in "${RELAYS[@]}"; do
    ssh "${AUTHORITY_SSH}" "docker swarm join --token ${TOKEN} ${relay}:2377"
done

log_success "Swarm Nodes Joined Successfully!"

log_info "Deploying Services to Swarm..."
docker stack deploy --compose-file "${COMPOSE_FILE}" swarm
