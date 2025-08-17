#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"

nodes=("authority" "relay1" "relay2" "exit1" "client")

BOOTSTRAP_SLEEP=1
MAX_TIME_TO_BOOTSTRAP=60
PERFORMANCE_BOOTSTRAP_COUNTER=5
DOCKER_COMPOSE_FILE="docker-compose.yml"

launch_tor_network() {

    # for node in "${nodes[@]}"; do
    #     ssh "$node" "sudo systemctl restart docker"
    # done
    # sleep 10
    
    while true; do
        COMPOSE_BAKE=true docker compose up -d
        #ssh authority docker stack deploy -q --detach=false -c Thesis/swarm.docker-compose.yml thesis

        local start end elapsed

        start=$(date +%s)
        end=$(date +%s)
        elapsed=$((end - start))

        sleep 20

        while [ $elapsed -lt $MAX_TIME_TO_BOOTSTRAP ]; do
            sleep "$BOOTSTRAP_SLEEP"
            #log_info "launch_tor_network()" "Checking if Tor Network is bootstrapped... ($elapsed s)"
            a=$(check_bootstrapped)
            if [ "$a" -eq $PERFORMANCE_BOOTSTRAP_COUNTER ]; then
                break 2
            fi

            end=$(date +%s)
            elapsed=$((end - start))
            if [[ "$VERBOSE" == true ]]; then
                echo -ne "⚠️ \e[33mWarning: Tor Network is not bootstrapped yet! ($a of $PERFORMANCE_BOOTSTRAP_COUNTER) [$elapsed s]\e[0m"\\r
            fi
        done
        echo 
        log_error "launch_tor_network()                                             " "Tor Network failed to bootstrap within $MAX_TIME_TO_BOOTSTRAP seconds. Retrying..."
        docker compose down --remove-orphans
        #ssh authority docker stack rm -d=false thesis
        echo
        #sleep 25
    done

    echo
}

docker_clean() {
    #ssh authority docker stack rm -d=false thesis
    docker compose down
}

set_configuration() {
    local params config_path dummy min_j max_j sched target_j dp_dist dp_epsilon

    params="$1"
    config_path="${CONFIG["absolute_path_dir"]}/${CONFIG["configuration_dir"]}"

    dummy=$(echo "$params" | jq -r '.dummy')
    min_j=$(echo "$params" | jq -r '.min_jitter')
    max_j=$(echo "$params" | jq -r '.max_jitter')
    sched=$(echo "$params" | jq -r '.scheduler')
    target_j=$(echo "$params" | jq -r '.target_jitter')
    dp_dist=$(echo "$params" | jq -r '.dp_distribution')
    dp_epsilon=$(echo "$params" | jq -r '.dp_epsilon')

    sed -i "s/^Schedulers .*/Schedulers ${sched}/" "${config_path}"tor.common.torrc

    sed -i "s/^PrivSchedulerDistribution .*/PrivSchedulerDistribution ${dp_dist}/" "${config_path}"tor.common.torrc
    sed -i "s/^PrivSchedulerEpsilon .*/PrivSchedulerEpsilon ${dp_epsilon}/" "${config_path}"tor.common.torrc

    sed -i "s/^PrivSchedulerMinJitter .*/PrivSchedulerMinJitter ${min_j}/" "${config_path}"tor.common.torrc
    sed -i "s/^PrivSchedulerMaxJitter .*/PrivSchedulerMaxJitter ${max_j}/" "${config_path}"tor.common.torrc
    sed -i "s/^PrivSchedulerTargetJitter .*/PrivSchedulerTargetJitter ${target_j}/" "${config_path}"tor.common.torrc

    sed -i "s/^DummyCellEpsilon .*/DummyCellEpsilon ${dummy}/" "${config_path}"tor.common.torrc

    # for node in "${nodes[@]}"; do
    #     log_info "set_configuration()" "Setting configuration for $node"
    #     scp -r "${config_path}" "$node:/home/ubuntu/Thesis/testing/"
    # done

}
