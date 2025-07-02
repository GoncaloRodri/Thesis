#!/bin/bash

declare -A CONFIG
declare -a EXPERIMENTS
declare -a COMBINATIONS

VERBOSE=false
BUILD=false

log() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "$@" >&2
    fi
}

log_info() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "💬 \e[34m$*\e[0m" >&2
    fi
}

log_error() {
    echo -e "\a❌ \e[31mError: $1\e[0m ❌" >&2
    shift 1
    echo -e "   $*" >&2
}

log_warning() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "\a⚠️ \e[33mWarning: $*\e[0m" >&2
    fi
}

log_success() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "✔️ \e[32m$*\e[0m" >&2
    fi
}

log_fatal() {
    echo -e "\a🚨 \e[31mFatal Error: $1\e[0m 🚨" >&2
    shift 1
    echo -e "   $*" >&2
    exit 1
}

# Load YAML config
load_config() {
    local config_file="$1"

    # Load base config
    CONFIG+=(
        ["repeat"]=$(yq eval '.config.repeat' "$config_file")
        ["clients"]=$(yq eval '.config.clients' "$config_file")
        ["logs_dir"]=$(yq eval '.config.logs_dir' "$config_file")
        ["copy_logs"]=$(yq eval '.config.copy_logs' "$config_file")
        ["docker_dir"]=$(yq eval '.config.docker_dir' "$config_file")
        ["data_dir"]=$(yq eval '.config.data_dir' "$config_file")
        ["results_dir"]=$(yq eval '.config.results_dir' "$config_file")
        ["tcpdump_mode"]=$(yq eval '.config.tcpdump_mode' "$config_file")
        ["absolute_path_dir"]=$(yq eval '.config.absolute_path' "$config_file")
        ["top_website_path"]=$(yq eval '.config.top_website_path' "$config_file")
        ["configuration_dir"]=$(yq eval '.config.configuration_dir' "$config_file")
    )

    # Load experiments
    local experiments_count
    experiments_count=$(yq eval '.experiments | length' "$config_file")
    for ((u = 0; u < experiments_count; u++)); do
        EXPERIMENTS+=("$(yq eval ".experiments[$u]" "$config_file" -o=json)")
    done
    # shellcheck disable=SC2034
    COMBINATIONS=("$(yq eval ".combinations" "$config_file" -o=json)")

}

show_help() {
    cat <<EOF
Experimental Runner v1.0

Usage: ./monitor.sh -c CONFIG_FILE [OPTIONS]

Options:
  -c, --config FILE    Specify YAML config file (required)
  -v, --verbose        Enable verbose output
  -h, --help           Show this help message

Config File Structure:
  config:
    absolute_path: string
    repeat: uint
    copy_logs: bool
    logs_dir: string
    docker_dir: string
    copy_target: string
    configuration_dir: string
  
  experiments:
    - name: string
      end_test_at: uint
      tcpdump_mode: bool
      filesize: ["5KB" | "1MB" | "5MB"]
      tor:
        dummy: [0-100]
        max_jitter: [0-inf]
        min_jitter: [0-max_jitter]
        target_jitter: [min_jitter-max_jitter]
        dp_distribution: ["UNIFORM" | "EXPONENTIAL"]
        dp_epsilon: [0.0-1.0]
        scheduler: ["Vanilla" | "KIST" | "DPVanilla" | "DPKist" ]
      clients:
        bulk_clients: uint
        web_clients: uint
        top_web_clients: uint
EOF
}

check_bootstrapped() {
    logs_path="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}*"
    # shellcheck disable=SC2086
    BSED=$(grep -l -R "Bootstrapped 100%" $logs_path | wc -l)
    echo "$BSED"
}

handle_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -c | --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        -v | --verbose)
            VERBOSE=true
            shift
            ;;
        -b | --build)
            # shellcheck disable=SC2034
            BUILD=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        esac
    done

    if [[ -z "${CONFIG_FILE}" ]]; then
        log_fatal "Config file is required!" "Use -c or --config to specify it." "\n   Use -h or --help to see all options."
    fi

    load_config "$CONFIG_FILE"
}

# shellcheck disable=SC2028
verify_config() {
    local abs_path="${CONFIG["absolute_path_dir"]}/"

    if [ -d "$abs_path" ]; then
        log_success "Directory exists: $abs_path"
    else
        log_fatal "verify_config()" "Absolute directory $abs_path does not exist!"
    fi

    local docker_dir="${abs_path}${CONFIG["docker_dir"]}"
    if [ -d "$docker_dir" ]; then
        log_success "Directory exists: $docker_dir"
    else
        log_fatal "verify_config()" "Docker directory $docker_dir does not exist!"
    fi

    local logs_dir="${abs_path}${CONFIG["logs_dir"]}"
    if [ -d "$logs_dir" ]; then
        log_success "Directory exists: $logs_dir"
        mkdir -p "${logs_dir}/curl"
    else
        log_fatal "verify_config()" "Logs directory $logs_dir does not exist!"
    fi

    local configuration_dir="${abs_path}${CONFIG["configuration_dir"]}"
    if [[ -d "$configuration_dir" ]]; then
        log_success "Directory exists: $configuration_dir"
    else
        log_fatal "verify_config()" "Configuration Directory $configuration_dir does not exist!"
    fi

    local data_dir="${abs_path}${CONFIG["data_dir"]}"
    local copy_logs=${CONFIG["copy_logs"]}
    if [ "$copy_logs" == "true" ] && [ -d "$data_dir" ]; then
        log_success "Directory exists: $data_dir"
    else
        log_error "verify_config()" "Copy Directory $data_dir does not exist!"
        mkdir -p "$data_dir" || log_fatal "Failed to create directory: $data_dir"
        log_success "Directory created: $data_dir"
    fi

    log_success "Configuration verified successfully."
}

debug_running_processes() {
    local name="$1"
    log_info "=== DEBUG: Checking running processes for test: $name ==="

    # Check for curl processes
    echo "Curl processes:"
    pgrep -f curl || echo "No curl processes found"

    # Check for bash processes (your client scripts)
    echo "Client script processes:"
    pgrep -f "run_webclient\|run_bulkclient" || echo "No client script processes found"

    # Check for timeout processes
    echo "Timeout processes:"
    pgrep -f timeout || echo "No timeout processes found"
}

cleanup_test_processes() {
    local name="$1"
    log_info "Cleaning up processes for test: $name"

    # Kill curl processes
    pkill -f curl 2>/dev/null || true

    # Kill timeout processes
    pkill -f timeout 2>/dev/null || true

    # Kill client script processes
    pkill -f "run_webclient\|run_bulkclient" 2>/dev/null || true

    #kill -KILL $(pgrep bash)

    # Clean up Docker container processes
    for container in "${CONTAINERS[@]}"; do
        docker exec "thesis-${container}-1" pkill -f curl 2>/dev/null || true
        docker exec "thesis-${container}-1" pkill -f bash 2>/dev/null || true
    done

    # Wait a bit for cleanup
    sleep 2
}
