#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/build.sh"
source "${SCRIPT_DIR}/clients.sh"

run_experiment() {
    local repeat name tcpdump_mode end_test_at client_params tor_params

    repeat=${CONFIG["repeat"]}
    name="$1"
    file_size="$2"
    end_test_at="$3"
    client_params="$4"
    tor_params="$5"

    # Client Params
    bulk_clients=$(echo "$client_params" | jq -r '.bulk_clients')
    web_clients=$(echo "$client_params" | jq -r '.web_clients')
    top_web_clients=$(echo "$client_params" | jq -r '.top_web_clients')

    for ((ii = 0; ii < $((repeat)); ii++)); do

        # Run the performance experiment
        log_info "Launching '$name-$ii'"
        if [ -n "$top_web_clients" ] && [ "$top_web_clients" -gt 0 ]; then
            mkdir -p "${CONFIG["absolute_path_dir"]}/${CONFIG["data_dir"]}/obs-$name-$ii"
        elif [ -n "$bulk_clients" ] && [ -n "$web_clients" ] && { [ "$bulk_clients" -gt 0 ] || [ "$web_clients" -gt 0 ]; }; then
            mkdir -p "${CONFIG["absolute_path_dir"]}/${CONFIG["data_dir"]}/perf-$name-$ii"
        fi

        log_info "Cleaning up Docker containers and images..."
        #docker_clean
        log_success "Docker cleanup Completed!\n"

        log_info "Setting up Torrc Configuration..."
        #set_configuration "$tor_params"
        log_success "Torrc Configuration Completed!\n"

        log_info "Launching Virtual Tor Network..."
        #launch_tor_network
        log_success "Virtual Tor Network Launched!\n"

        if [ -n "$top_web_clients" ] && [ "$top_web_clients" -gt 0 ]; then
            log_info "Starting Top Websites Clients Experiment..."
            launch_topweb_clients "obs-$name" "$ii"
            log_info "Bulk/Web Clients Experiment Completed!"
        elif [ -n "$bulk_clients" ] && [ -n "$web_clients" ] && { [ "$bulk_clients" -gt 0 ] || [ "$web_clients" -gt 0 ]; }; then
            log_info "Starting Bulk/Web Clients Experiment..."
            launch_localclients "perf-$name" "$file_size" "$ii"
            log_info "Bulk/Web Clients Experiment Completed!"
        else
            # shellcheck disable=SC2140
            log_fatal "run_performance_experiment()" "Number of clients wrongly specified in the configuration. Set "bulk_clients" and "web_clients" or "top_web_clients" in the experiment params."
        fi

        log_success "Performance Experiment Successful!\n"

        if [ "${CONFIG["copy_logs"]}" = true ]; then
            save_logs "$name" "$ii" "$file_size" "$tor_params" "$client_params" "$top_web_clients"
        fi

    done
}

save_logs() {
    if [ "${CONFIG["local"]}" = false ]; then
        from=(
            authority
            relay1
            relay2
            exit1
            client
        )

        for node in "${from[@]}"; do
            log_info "Copying logs from $node"
            scp -r "$node:~/Thesis/testing/logs/tor/*" "${CONFIG["absolute_path_dir"]}/testing/logs/tor"
            scp -r "$node:~/Thesis/testing/logs/wireshark/*" "${CONFIG["absolute_path_dir"]}/testing/logs/wireshark"
        done

        log_success "Logs copied from machines successfully!"
    fi

    logs_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}"
    if [ "$6" -gt 0 ]; then
        copy_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["data_dir"]}obs-$1-$2"
    else
        copy_dir="${CONFIG["absolute_path_dir"]}/${CONFIG["data_dir"]}perf-$1-$2"
    fi

    log_info "Copying cURL logs"
    mkdir -p "${copy_dir}"
    # Copy cURL logs
    if [ "$6" -le 0 ]; then
        cp -r "${logs_dir}curl.log" "${copy_dir}"
        rm -rf "${logs_dir}curl.log" || log_fatal "Failed to clean cURL logs directory: ${logs_dir}curl.log"
    fi

    log_info "Copying Tor logs"

    # Copy Tor logs
    mkdir -p "${copy_dir}/tor"
    cp -r "${logs_dir}tor" "${copy_dir}"

    # Copy pcap logs
    if [ "$6" -gt 0 ]; then
        log_info "Copying pcap logs"
        zip -r "${copy_dir}/$1.zip" "${logs_dir}wireshark/" || log_fatal "Failed to zip pcap logs"
        rm -rf "${logs_dir}wireshark/" || log_fatal "Failed to clean pcap logs directory: ${logs_dir}wireshark/"
    fi

    echo '{
        "name": "'"$1"'",
        "file_size": "'"$3"'",
        "tor_params": '"$4"',
        "client_params": '"$5"'
    }' >"${copy_dir}/info.json"

    log_success "Logs copied to ${copy_dir} successfully!"
}

run_combinations() {
    TCP_DUMP_MODE=$(echo "$COMBINATIONS" | jq '.tcpdump')

    FILESIZE_LIST=$(echo "$COMBINATIONS" | jq '.filesize')
    NUM_FILESIZE=$(echo "$FILESIZE_LIST" | jq 'length')

    CLIENTS_LIST=$(echo "$COMBINATIONS" | jq '.clients')
    NUM_CLIENTS=$(echo "$CLIENTS_LIST" | jq 'length')

    DUMMY_LIST=$(echo "$COMBINATIONS" | jq '.tor.dummy')
    NUM_DUMMY=$(echo "$DUMMY_LIST" | jq 'length')

    MAX_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.max_jitter')
    NUM_MAX_JITTER=$(echo "$MAX_JITTER_LIST" | jq 'length')

    MIN_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.min_jitter')
    NUM_MIN_JITTER=$(echo "$MIN_JITTER_LIST" | jq 'length')

    TARGET_JITTER_LIST=$(echo "$COMBINATIONS" | jq '.tor.target_jitter')
    NUM_TARGET_JITTER=$(echo "$TARGET_JITTER_LIST" | jq 'length')

    DP_DIST_LIST=$(echo "$COMBINATIONS" | jq '.tor.dp_distribution')
    NUM_DP_DIST=$(echo "$DP_DIST_LIST" | jq 'length')

    DP_EPSILON_LIST=$(echo "$COMBINATIONS" | jq '.tor.dp_epsilon')
    NUM_DP_EPSILON=$(echo "$DP_EPSILON_LIST" | jq 'length')

    SCHEDULER_LIST=$(echo "$COMBINATIONS" | jq '.tor.scheduler')
    NUM_SCHEDULER=$(echo "$SCHEDULER_LIST" | jq 'length')

    TOTAL_COMBINATIONS_COUNT=$((NUM_CLIENTS * NUM_DUMMY * NUM_MAX_JITTER * NUM_MIN_JITTER * NUM_TARGET_JITTER * NUM_DP_DIST * NUM_DP_EPSILON * NUM_SCHEDULER * NUM_FILESIZE))


    for ((i = 0; i < NUM_CLIENTS; i++)); do
        for ((j = 0; j < NUM_DUMMY; j++)); do
            for ((k = 0; k < NUM_MAX_JITTER; k++)); do
                for ((ll = 0; ll < NUM_MIN_JITTER; ll++)); do
                    for ((m = 0; m < NUM_TARGET_JITTER; m++)); do
                        for ((n = 0; n < NUM_DP_DIST; n++)); do
                            for ((o = 0; o < NUM_DP_EPSILON; o++)); do
                                for ((p = 0; p < NUM_SCHEDULER; p++)); do
                                    for ((q = 0; q < NUM_FILESIZE; q++)); do
                                        tor_params=$(jq -n \
                                            --arg dummy "$(echo "$DUMMY_LIST" | jq -r ".[$j]")" \
                                            --arg max_jitter "$(echo "$MAX_JITTER_LIST" | jq -r ".[$k]")" \
                                            --arg min_jitter "$(echo "$MIN_JITTER_LIST" | jq -r ".[$ll]")" \
                                            --arg target_jitter "$(echo "$TARGET_JITTER_LIST" | jq -r ".[$m]")" \
                                            --arg dp_distribution "$(echo "$DP_DIST_LIST" | jq -r ".[$n]")" \
                                            --arg dp_epsilon "$(echo "$DP_EPSILON_LIST" | jq -r ".[$o]")" \
                                            --arg scheduler "$(echo "$SCHEDULER_LIST" | jq -r ".[$p]")" \
                                            '{dummy: $dummy, max_jitter: $max_jitter, min_jitter: $min_jitter, target_jitter: $target_jitter, dp_distribution: $dp_distribution, dp_epsilon: $dp_epsilon, scheduler: $scheduler}')

                                        client_params=$(jq -n \
                                            --arg bulk_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][0]")" \
                                            --arg web_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][1]")" \
                                            --arg top_web_clients "$(echo "$CLIENTS_LIST" | jq -r ".[$i][2]")" \
                                            '{bulk_clients: ($bulk_clients | tonumber), web_clients: ($web_clients | tonumber), top_web_clients: ($top_web_clients | tonumber)}')
                                        file_size=$(echo "$FILESIZE_LIST" | jq -r ".[$q]")

                                        #SCHED - DIST - EPSILON - DUMMY - CLIENT_RATIO - FILESIZE
                                        totalC="$(echo "$CLIENTS_LIST" | jq -r ".[$i][0] + .[$i][1] + .[$i][2]")"
                                        name="$(echo "$SCHEDULER_LIST" | jq -r ".[$p]")-$(echo "$DP_DIST_LIST" | jq -r ".[$n]")-$(echo "$DP_EPSILON_LIST" | jq -r ".[$o]")-$(echo "$DUMMY_LIST" | jq -r ".[$j]")dum-${totalC}Clients-$file_size"
                                        run_experiment "$name" "$file_size" ""${CONFIG["end_test_at"]}"" "$client_params" "$tor_params"
                                    done
                                done
                            done
                        done
                    done
                done
            done
        done
    done

    log_success "All combinations executed successfully!"
}
