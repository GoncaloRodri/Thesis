#!/bin/bash

SOURCES_DIRECTORY="/home/guga/Documents/Thesis/testing/filtered_collections"
DEST_FOLDER="/home/guga/Documents/Thesis/testing/results/observations"
RESULTS_FOLDER="./data/results"
PCAP_FOLDER="./data/pcaps"
MODELS_FOLDER="./data/models"
OUTPUT_PROGRAM_FOLDER="./data/output"
SHOW_CLI=true

show_spinner() {
    local pid=$1
    local delay=0.2
    local spin='⠋⠙⠸⠴⠦⠇'
    while ps -p $pid > /dev/null 2>&1; do
        for i in $(seq 0 $((${#spin}-1))); do
            printf "\r🚀 Running program... %s" "${spin:$i:1}"
            sleep $delay
        done
    done
    printf "\r✅ Program finished!          \n"
}

cd wf-pipeline

for SUB in "${SOURCES_DIRECTORY}"/*/; do
    if [ -d "$SUB" ]; then
        SUB_NAME=$(basename "$SUB")
        SUB_RESULTS_FOLDER="$DEST_FOLDER/$SUB_NAME"
        echo "🔄 Processing: $SUB_NAME"
        echo "   Results added on $SUB_RESULTS_FOLDER"

        echo "📂 Copying from $INPUT_FOLDER to $PCAP_FOLDER..."

        rm -rf ${MODELS_FOLDER}/*
        rm -rf ${PCAP_FOLDER}/*
        rm -rf ${OUTPUT_PROGRAM_FOLDER}/*

        cp -r ${SUB}* ${PCAP_FOLDER}/

        echo "🚀 Running program..."
        mkdir -p "$SUB_RESULTS_FOLDER"
        cd src-ml

        if [ $SHOW_CLI = true ]; then
            (sh -c ./main.sh | tee "$SUB_RESULTS_FOLDER/observer.log")
        else
            (sh -c ./main.sh >"$SUB_RESULTS_FOLDER/observer.log")
        fi

        cd ..

        echo ""📦 Saving results...""
        mv "$RESULTS_FOLDER" "$SUB_RESULTS_FOLDER"/

        echo "✅ Finished processing: $SUB_NAME"
    fi

    exit 0

done

echo "Finished observing source pcap files."

