FROM ubuntu:latest

# Install dependencies
RUN apt update && apt install -y \
    libssl-dev libevent-dev zlib1g-dev liblzma-dev libzstd-dev \
    libcap-dev libseccomp-dev build-essential python3 python3-stem pkg-config \
    automake git cmake libglib2.0-dev libigraph-dev \ 
tcpdump curl python3-dev python3.12-venv python3-pip dnsutils
