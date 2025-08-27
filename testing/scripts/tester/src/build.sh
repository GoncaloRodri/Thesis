#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

nodes=("authority" "relay1" "relay2" "exit1" "client")

BOOTSTRAP_SLEEP=1
MAX_TIME_TO_BOOTSTRAP=40
PERFORMANCE_BOOTSTRAP_COUNTER=5
DOCKER_COMPOSE_FILE="docker-compose.yml"


launch_tor_network() {

    elapsed_to_complete=$(date +%s)
    tests_counter=0

    if [ "${CONFIG[local]}" = false ]; then
        for node in "${nodes[@]}"; do
            ssh "$node" "sudo systemctl restart docker"
        done
        sleep 10
    fi

    while true; do
        if [ "${CONFIG[local]}" = true ]; then
            COMPOSE_BAKE=true docker-compose up -d
        else
            ssh authority docker stack deploy -q --detach=false -c Thesis/swarm.docker-compose.yml thesis
        fi
    
        tests_counter=$((tests_counter + 1))

        local start end elapsed

        start=$(date +%s)
        end=$(date +%s)
        elapsed=$((end - start))

        a=0
        sleep 20


        while { [ $elapsed -lt $MAX_TIME_TO_BOOTSTRAP ] && { [ "$a" -ne 0 ] || [ "$elapsed" -lt 20 ]; }; }; do
            if [ ${CONFIG["local"]} = true ]; then
                sleep $BOOTSTRAP_SLEEP
            fi

            a=$(check_bootstrapped)

            end=$(date +%s)
            elapsed=$((end - start))
            
            if [ "$a" -eq $PERFORMANCE_BOOTSTRAP_COUNTER ]; then
                elapsed_to_complete=$(($(date +%s) - elapsed_to_complete))
                echo "Test Nº $tests_counter: $elapsed secs of $elapsed_to_complete secs" >> elapsed_to_complete.log
                break 2
            fi

            if [[ "$VERBOSE" == true ]]; then
                echo -ne "⚠️ \e[33mWarning: Tor Network is not bootstrapped yet! ($a of $PERFORMANCE_BOOTSTRAP_COUNTER) [$elapsed s]\e[0m"\\r
            fi
        done
        echo 
        log_error "launch_tor_network()                                             " "Tor Network failed to bootstrap within $MAX_TIME_TO_BOOTSTRAP seconds. Retrying..."
        docker_clean
        echo
        sleep 25
    done

    echo ""
}

docker_clean() {
    if [ "${CONFIG[local]}" = true ]; then
        docker-compose down
    else
        ssh authority docker stack rm -d=false thesis
    fi
}

set_configuration() {
    local params config_path dummy min_j max_j sched target_j dp_dist dp_epsilon

    params="$1"
    config_path="${CONFIG[absolute_path_dir]}/${CONFIG[configuration_dir]}"

    dummy=$(echo "$params" | jq -r '.dummy')
    min_j=$(echo "$params" | jq -r '.min_jitter')
    max_j=$(echo "$params" | jq -r '.max_jitter')
    sched=$(echo "$params" | jq -r '.scheduler')
    target_j=$(echo "$params" | jq -r '.target_jitter')
    dp_dist=$(echo "$params" | jq -r '.dp_distribution')
    dp_epsilon=$(echo "$params" | jq -r '.dp_epsilon')

    sed -i "s/^Schedulers .*/Schedulers ${sched}/" "${config_path}tor.common.torrc"

    sed -i "s/^PrivSchedulerDistribution .*/PrivSchedulerDistribution ${dp_dist}/" "${config_path}tor.common.torrc"
    sed -i "s/^PrivSchedulerEpsilon .*/PrivSchedulerEpsilon ${dp_epsilon}/" "${config_path}tor.common.torrc"

    sed -i "s/^PrivSchedulerMinJitter .*/PrivSchedulerMinJitter ${min_j}/" "${config_path}tor.common.torrc"
    sed -i "s/^PrivSchedulerMaxJitter .*/PrivSchedulerMaxJitter ${max_j}/" "${config_path}tor.common.torrc"
    sed -i "s/^PrivSchedulerTargetJitter .*/PrivSchedulerTargetJitter ${target_j}/" "${config_path}tor.common.torrc"

    sed -i "s/^DummyCellEpsilon .*/DummyCellEpsilon ${dummy}/" "${config_path}tor.common.torrc"

    if [ "${CONFIG[local]}" = false ]; then
        for node in "${nodes[@]}"; do
            log_info "set_configuration()" "Setting configuration for $node"
            scp -r "${config_path}" "$node:/home/ubuntu/Thesis/testing/"
        done
    fi
}
