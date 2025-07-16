#!/bin/bash

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ABS_DIR="$(cd "${SCRIPT_DIR}/../../../" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"

BOOTSTRAP_SLEEP=1
MAX_TIME_TO_BOOTSTRAP=300
PERFORMANCE_BOOTSTRAP_COUNTER=5
COMPOSE_FILE="${ABS_DIR}/swarm.docker-compose.yml"

AUTHORITY_IP="127.0.0.1"

TOKEN=""

VERBOSE=true

RELAYS=(
)

clean() {
    log_info "Cleaning up Swarm environment..."
    docker stack rm thesis || true
    docker swarm leave --force || true
    docker network rm swarm || true
    docker service rm $(docker service ls -q) || true
    echo
}

connect() {
    log_info "Building Docker images..."
    docker buildx build -t gugarodri/dptor_node:latest -f "${ABS_DIR}"/testing/docker/node.Dockerfile "${ABS_DIR}"/
    docker buildx build -t gugarodri/dptor_httpserver:latest -f "${ABS_DIR}"/testing/docker/httpserver.Dockerfile "${ABS_DIR}"/
    
    log_info "Pushing Docker images to registry..."
    docker push gugarodri/dptor_node:latest
    docker push gugarodri/dptor_httpserver:latest

    

    log_info "Initializing Docker Swarm..."
    SWARM_JOIN_CMD=$(docker swarm init --advertise-addr "${AUTHORITY_IP}" | grep "join --token")

    log_info "Swarm initialized with token: ${TOKEN}"

    log_info "Creating Docker network..."
    docker network create --driver overlay --attachable swarm

    # for relay in "${RELAYS[@]}"; do
    #     ssh "${relay}" "${SWARM_JOIN_CMD}"
    # done

    #ssh "${CLIENT}" "${SWARM_JOIN_CMD}"

}

check_boot() {
    logs_path="${ABS_DIR}/testing/logs/tor/*"
    # shellcheck disable=SC2086
    BSED=$(grep -l -R "Bootstrapped 100%" $logs_path | wc -l)
    echo "$BSED"
}

get_server_ip() {
    "$(docker exec "$(docker container ls | grep "server" | awk '{print $1}')" hostname -i )"
}

get_client_id() {
    "$(docker container ls | grep "client" | awk '{print $1}')"
}

deploy() {
    while true; do
        log_info "Deploying Services to Swarm..."
        docker stack deploy --detach=false -c "${COMPOSE_FILE}" thesis

        START=$(date +%s)
        END=$(date +%s)
        ELAPSED=$((END - START))

        while [ $ELAPSED -lt $MAX_TIME_TO_BOOTSTRAP ]; do
            sleep "$BOOTSTRAP_SLEEP"
            a=$(check_boot)
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

}

request() {
   curl --socks5 127.0.0.1:9000 -H 'Cache-Control: no-cache' -w "Code: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null "$(get_server_ip)":5000/bytes/"$2"
}
run() {
    log_info "Running tests against the Swarm deployment..."

    request "51200"
}


clean
connect
deploy
run

log_sucess "Swarm deployment and tests completed successfully!"
