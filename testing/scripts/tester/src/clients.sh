#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/request.sh"

CONTAINERS=("client" "relay1" "relay2" "exit1" "authority")

launch_clients() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    local test_timeout="$4"
    local bulk_clients="$5"
    local web_clients="$6"
    local tcpdump_mode="$7"

    abs_path=${CONFIG["absolute_path_dir"]}

    for ((kl = 0; kl < web_clients; kl++)); do
        log_file_path="$abs_path/backup/${name}-${test_count}/curl.log"
        timeout --preserve-status --kill-after=5s "${test_timeout}s" \
            bash -c '
                trap "kill -- -$$" SIGTERM; 
                cd "'"$abs_path"'"/scripts/tester
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src"
                source "${SCRIPT_DIR}/utils.sh"
                source "${SCRIPT_DIR}/request.sh"
                run_webclient "'"$log_file_path"'" "'"$filesize"'"
            ' &
        client_pids+=($!)
    done

    for ((lk = 0; lk < bulk_clients; lk++)); do
        log_file_path="$abs_path/backup/${name}-${test_count}/curl.log"
        timeout --preserve-status --kill-after=5s "${test_timeout}s" \
            bash -c '
                trap "kill -- -$$" SIGTERM; 
                cd "'"$abs_path"'"/scripts/tester
                SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/src"
                source "${SCRIPT_DIR}/utils.sh"
                source "${SCRIPT_DIR}/request.sh"
                run_bulkclient "'"$log_file_path"'" "'"$filesize"'"
            ' &
        client_pids+=($!)
    done

    log_info "Ending bulk clients for $name after $test_timeout seconds..."
    sleep "$((test_timeout + 10))"

    log_info "Checking for lingering processes after timeout..."
    debug_running_processes

    log_info "Killing lingering processes for $name..."
    for pid in "${client_pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Killing lingering process $pid"
            kill -TERM "$pid" 2>/dev/null || true
            sleep 1
            kill -KILL "$pid" 2>/dev/null || true
        fi
    done

    wait
    #cleanup_test_processes

    log_info "Double-checking for lingering processes after cleanup..."
    debug_running_processes

    log_success "All clients for $name have completed."
}

launch_localclients() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    log_file_path=$(get_logfile)
    run_localclient "$log_file_path" "$filesize"
}

start_tcpdump() {
    for container in "${CONTAINERS[@]}"; do
        start_tcpdump_on_relay "$container" "$1" "$2" &
    done
    wait
}

stop_tcpdump() {
    for container in "${CONTAINERS[@]}"; do
        stop_tcpdump_on_relay "$container"
    done
}

start_tcpdump_on_relay() {
    local relay_name="$1"
    local id="$2"
    ssh "$1" sh -c "(tcpdump -i eth0 -w ~/Thesis/testing/logs/wireshark/${relay_name}/${id}.pcap)"
}

stop_tcpdump_on_relay() {
    local relay_name="$1"
    ssh "$1" sh -c "pkill tcpdump"
}
    
run_topwebclient() {
    local name="$1"
    shift 1
    local urls=("$@")

    if [[ ${#urls[@]} -eq 0 ]]; then
        log_fatal "run_topwebclient()" "No URLs provided for top web client."
    fi

    log_info "Starting Top Web Client for $name"

    for url in "${urls[@]}"; do
        if [[ -z "$url" ]]; then
            log_error "run_topwebclient()" "URL is empty, skipping..."
            continue
        fi
        start_tcpdump "$name" "$url"
        log="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}curl_website.log"
        echo "⚠️ \e[33mExecuting Curl Request [${url}]                   \e[0m"\\r
        exec_website_curl "$url" "$log"
        sleep 1
        stop_tcpdump
    done
}

launch_topweb_clients() {
    echo "Launching top web clients..."
    local name="$1"
    local test_count="$2"

    local file_path="${CONFIG["absolute_path_dir"]}/${CONFIG["top_website_path"]}"

    if [[ ! -f "$file_path" ]]; then
        log_fatal "fetch_topweb_urls()" "Top websites file not found: $file_path"
    fi

    websites=()
    while IFS= read -r line; do
        websites+=("www.${line}")
    done <"$file_path"

    if [[ ${#websites[@]} -eq 0 ]]; then
        log_fatal "launch_topweb_clients()" "No URLs found in the top websites file."
    fi

    echo "Top websites loaded: ${websites[*]} URLs"

    log_info "Requesting Top Websites..."
    
    run_topwebclient "$name" "${websites[@]}"

    log_success "Top web clients for $name have completed."
}
