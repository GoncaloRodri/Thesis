#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/utils.sh"
source "${SCRIPT_DIR}/request.sh"

CONTAINERS=("client" "relay1" "relay2" "exit1" "authority")

launch_localclients() {
    local name="$1"
    local filesize="$2"
    local test_count="$3"
    log_file_path=$(get_logfile)
    run_localclient "$log_file_path" "$filesize"
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
