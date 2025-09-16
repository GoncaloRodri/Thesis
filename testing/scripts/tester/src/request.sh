#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/utils.sh"

RANDOM_INTERVAL=5


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
    local url="$2"
    local sample_n="$3"
    if [ "${CONFIG["local"]}" = true ]; then
        docker exec "thesis_${relay_name}_1" sh -c "(tcpdump -i eth0 -w /app/logs/wireshark/${relay_name}/${url}_${sample_n}.pcap)" & 
    else
        ssh -f "$1" "sudo tcpdump -i ens3 -w ~/Thesis/testing/logs/wireshark/${relay_name}/${url}_${sample_n}.pcap"
    fi

}

stop_tcpdump_on_relay() {
    local relay_name="$1"
    if [ "${CONFIG["local"]}" = true ]; then
        docker exec "thesis_${relay_name}_1" sh -c "pkill tcpdump"
    else
        ssh "$1" "sudo pkill tcpdump"
    fi
}

download_curl() {
    local log_file="$2"
    if [ "${CONFIG["local"]}" = true ]; then
        curl --socks5 127.0.0.1:9000 -H 'Cache-Control: no-cache' -w 'Code: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n' -o /dev/null 10.5.0.200:5000/bytes/${1} >>"$log_file"
    else
        ssh client "curl --socks5 127.0.0.1:9000 -H 'Cache-Control: no-cache' -w 'Code: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n' -o /dev/null 54.36.191.12:5000/bytes/${1}" >>"$log_file"
    fi
}

browse_curl() {
    local log_file="$1"
    if [ "${CONFIG["local"]}" = true ]; then
        curl --socks5 127.0.0.1:9000 -H 'Cache-Control: no-cache' --max-time 3 -w 'Code: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n' -o /dev/null ${2} >>"$log_file"
    else
        ssh client "curl --socks5 127.0.0.1:9000 --max-time 3 -H 'Cache-Control: no-cache' -w 'Code: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n' -o /dev/null ${2}" >>"$log_file"
    fi
}

get_logfile() {
    local logfile="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}curl.log"
    echo "$logfile"
}


run_localclient() {
    local filesize="$2"
    CURL_TEST_NUM="${CONFIG["end_test_at"]}"
    log_file="$(get_logfile)"
    log_info "run_localclient()" "Executing $CURL_TEST_NUM cURL requests with filesize $filesize bytes..."

    for ((curl_i = 0; curl_i < $((CURL_TEST_NUM)); curl_i++)); do
        echo -e "⚠️ \e[33mExecuting Curl Requests [$curl_i of $CURL_TEST_NUM]\e[0m"\\r
        download_curl "$filesize" "$log_file"
        sleep 1
    done
    echo -e "⚠️ \e[33mExecuting Curl Requests [100%]\e[0m"\\r
    log_info "run_localclient()" "Executed $CURL_TEST_NUM cURL requests successfully!"
}

run_topwebclient() {
    local name="$1"
    shift 1
    local urls=("$@")

    if [[ ${#urls[@]} -eq 0 ]]; then
        log_fatal "run_topwebclient()" "No URLs provided for top web client."
    fi

    log_info "Starting Top Web Client for $name"
    total_samples=$((50 * ${#urls[@]}))
    step=0
    log="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}curl_website.log"

    starting_time=$(date +%s)


    for sample in $(seq 30 50); do
        for url in "${urls[@]}"; do
            step=$((step + 1))
            percentage=$((step * 100 / total_samples))
            if [[ -z "$url" ]]; then
                log_error "run_topwebclient()" "URL is empty, skipping..."
                continue
            fi
            start_tcpdump "$url" "$sample"
            echo -e "⚠️ \e[33m Requesting ${url} [${step} of ${total_samples}] [${percentage}%]                   \e[0m"
            browse_curl "$log" "$url" "$sample" || log_error "run_topwebclient()" "Failed to execute curl request for ${url}. Moving on..."
            sleep 0.5
            stop_tcpdump
        done
    done

    duration=$(( $(date +%s) - starting_time ))
    echo -e "Test: $name | Duration: $duration seconds\n" >>"report.txt"
}