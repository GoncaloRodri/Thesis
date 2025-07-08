#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABS_DIR="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"

BOOTSTRAP_SLEEP=1
MAX_TIME_TO_BOOTSTRAP=90
PERFORMANCE_BOOTSTRAP_COUNTER=5
COMPOSE_FILE="${ABS_DIR}/swarm.docker-compose.yml"

AUTHORITY_IP="10.5.0.1"
AUTHORITY_SSH="root@${AUTHORITY_IP}"

TOKEN=""

VERBOSE=true

RELAYS=(
)

CLIENT="ubuntu@aaa"

connect() {
    docker buildx build -t gugarodri/dptor_node:latest -f "${ABS_DIR}"/testing/docker/node.Dockerfile "${ABS_DIR}"/

    docker push gugarodri/dptor_node:latest

    docker swarm leave --force || true

    TOKEN=$(docker swarm init --advertise-addr "${AUTHORITY_IP}")

    for relay in "${RELAYS[@]}"; do
        ssh "${relay}" "docker swarm join --token ${TOKEN} ${AUTHORITY_IP}:2377"
    done

    ssh "${CLIENT}" "docker swarm join --token ${TOKEN} ${AUTHORITY_IP}:2377"

}

run() {
    CLIENT_DOCKER_SERVICE=$(docker services ls | grep client | awk '{print $10}')

}

deploy() {
    docker stack rm thesis
    while true; do
        log_info "Deploying Services to Swarm..."
        docker stack deploy --detach=false -c "${COMPOSE_FILE}" thesis

        START=$(date +%s)
        END=$(date +%s)
        ELAPSED=$((END - START))

        while [ $ELAPSED -lt $MAX_TIME_TO_BOOTSTRAP ]; do
            sleep "$BOOTSTRAP_SLEEP"
            a=$(check_bootstrapped)
            if [ "$a" -eq $PERFORMANCE_BOOTSTRAP_COUNTER ]; then
                break 2
            fi
            END=$(date +%s)
            ELAPSED=$((END - START))
            if [[ "$VERBOSE" == true ]]; then
                echo -ne "⚠️ \e[33mWarning: Tor Network is not bootstrapped yet! ($a of $PERFORMANCE_BOOTSTRAP_COUNTER) [$ELAPSED s]\e[0m"\\r
            fi
        done

        log_error "Swarm Deployment Failed" "Tor Network failed to bootstrap within $MAX_TIME_TO_BOOTSTRAP seconds. Retrying..."
        docker stack rm thesis
        sleep 3
    done

    run

}

log_info "Starting Swarm Experiment..."

while true; do
    log_info "Deploying Services to Swarm..."
    docker stack deploy --detach=false -c "${COMPOSE_FILE}" thesis

    START=$(date +%s)
    END=$(date +%s)
    ELAPSED=$((END - START))

    while [ $ELAPSED -lt $MAX_TIME_TO_BOOTSTRAP ]; do
        sleep "$BOOTSTRAP_SLEEP"
        a=$(check_bootstrapped)
        if [ "$a" -eq $PERFORMANCE_BOOTSTRAP_COUNTER ]; then
            break 2
        fi
        END=$(date +%s)
        ELAPSED=$((END - START))
        if [[ "$VERBOSE" == true ]]; then
            echo -ne "⚠️ \e[33mWarning: Tor Network is not bootstrapped yet! ($a of $PERFORMANCE_BOOTSTRAP_COUNTER) [$ELAPSED s]\e[0m"\\r
        fi
    done

    log_error "Swarm Deployment Failed" "Tor Network failed to bootstrap within $MAX_TIME_TO_BOOTSTRAP seconds. Retrying..."
    docker stack rm thesis
done

log_info "Swarm Deployment Successful!"
