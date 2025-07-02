#!/bin/bash

set -eo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/utils.sh"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/src/run.sh"

handle_args "$@"

verify_config

for experiment in "${EXPERIMENTS[@]}"; do
    name=$(echo "$experiment" | jq -r '.name')
    tcpdump_mode=$(echo "$experiment" | jq -r '.tcpdump_mode')
    end_test_at=$(echo "$experiment" | jq -r '.end_test_at')
    file_size=$(echo "$experiment" | jq -r '.filesize')
    client_params=$(echo "$experiment" | jq -r '.clients')
    tor_params=$(echo "$experiment" | jq -r '.tor')

    run_experiment "$name" "$tcpdump_mode" "$file_size" "$end_test_at" "$client_params" "$tor_params"

done

run_combinations
