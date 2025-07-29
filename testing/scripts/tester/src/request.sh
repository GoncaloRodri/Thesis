#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/utils.sh"

RANDOM_INTERVAL=5

exec_curl() {
    local url="$1"
    local log_file="$2"
    curl --socks5 127.0.0.1:9000 -H 'Cache-Control: no-cache' -w "URL: $url\nCode: %{response_code}\nTime to first byte: %{time_starttransfer}s\nTotal time: %{time_total}s\nDownload speed: %{speed_download} bytes/sec\n" -o /dev/null "$url" >>"$log_file"
}
get_url() {
    #echo "http://ipv4.download.thinkbroadband.com/${1}.zip"
    local link="$(docker exec "$(docker container ls | grep "server" | awk '{print $1}')" hostname -i)"
    echo "${link}:5000/bytes/${1}"
}

get_logfile() {
    local logfile="${CONFIG["absolute_path_dir"]}/${CONFIG["logs_dir"]}curl.log"
    echo "$logfile"
}

run_webclient() {
    local url
    local log_file="$1"
    local filesize="$2"

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        
        sleep $((RANDOM % RANDOM_INTERVAL + 1))
        counter=$((counter + 1))
        exec_curl "$url" "$log_file"
        if ((counter % 10 == 0)); then
            echo -ne "⚠️ \e[33mExecuting Web Client Requests [$counter]\e[0m"\\r
        fi
        ((webcount++))
    done
    echo -ne "⚠️ \e[33mExecuting Web Client Requests [100%]\e[0m"\\r
}

run_bulkclient() {
    local url
    local log_file="$1"
    local filesize="$2"

    url=$(get_url "$filesize")
    local counter=0
    while true; do
        counter=$((counter + 1))
        exec_curl "$url" "$(get_logfile)"
        ((bulkcount++))
        sleep 0.5
    done
}

run_localclient() {
    local url
    local log_file="$1"
    local filesize="$2"
    CURL_TEST_NUM="${CONFIG["end_test_at"]}"

    url=$(get_url "$filesize")
    for ((curl_i = 0; curl_i < $((CURL_TEST_NUM)); curl_i++)); do
        echo -ne "⚠️ \e[33mExecuting Curl Requests [$curl_i of $CURL_TEST_NUM]\e[0m"\\r
        exec_curl "$url" "$(get_logfile)"
        sleep 1
    done
    echo -ne "⚠️ \e[33mExecuting Curl Requests [100%]\e[0m"\\r
    log_info "run_localclient()" "Executed $CURL_TEST_NUM cURL requests successfully!"
}
