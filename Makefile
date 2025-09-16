SHELL := /bin/bash

all: install docker-build docker-pull help

install:
	@sudo apt update -y
	@sudo apt install -y python3-dev python3-pip jq
	@sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
	@python3 -m venv .venv
	@./.venv/bin/python3 -m pip install --upgrade pip
	@./.venv/bin/pip install -r ./testing/scripts/requirements.txt
	@echo -e "\nInstallation complete. Activate the virtual environment using:."
	@echo "  source ./.venv/bin/activate"
	@echo ""

swarm-init:
	@sh -c "./testing/scripts/tester/swarm.sh -c testing/scripts/tester/config.yaml -v"
	
docker-build:
	@docker buildx build \
        -t gugarodri/dptor_base \
        -f testing/docker/base.Dockerfile \
        .
    
	@docker buildx build \
        -t gugarodri/dptor_node \
        -f testing/docker/node.Dockerfile \
        .
    
	@docker buildx build \
        -t gugarodri/dptor_swarm \
        -f testing/docker/swarm.Dockerfile \
        .
	
docker-push:
	@docker push gugarodri/dptor_base
	@docker push gugarodri/dptor_node
	@docker push gugarodri/dptor_swarm

#Test Resolves Manipulation and Handling

observe: testing/scripts/observer/observer.sh .venv/bin/activate
	@sh -c "./testing/scripts/observer/observer.sh"

analyze: testing/scripts/analyzer/analyzer.sh .venv/bin/activate
	@sh -c "./testing/scripts/analyzer/analyzer.sh"

plot: testing/scripts/plotter/plotter.sh .venv/bin/activate
	@sh -c "./testing/scripts/plotter/plotter.sh"

wrap: testing/scripts/wrapper/wrapper.sh
	@sh -c "./testing/scripts/wrapper/wrapper.sh"

# Test cases
jitter-perf: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/jitter.perf.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/jitter.perf.yaml -v"

jitter-obs: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/jitter.obs.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/jitter.obs.yaml -v"

dummy-perf: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/dummy.perf.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/dummy.perf.yaml -v"

dummy-obs: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/dummy.obs.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/dummy.obs.yaml -v"

jitterdummy-perf: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/jitterdummy.perf.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/jitterdummy.perf.yaml -v"

jitterdummy-obs: testing/scripts/tester/monitor.sh testing/scripts/tester/configs/jitterdummy.obs.yaml
	@sh -c "./testing/scripts/tester/monitor.sh -c testing/scripts/tester/configs/jitterdummy.obs.yaml -v"

help:
	@echo "Makefile commands:"
	@echo "  install  			- Install necessary dependencies"
	@echo "  swarm-init 		- Initialize Docker Swarm"
	@echo "  docker-build		- Build Docker images"
	@echo "  docker-push		- Push Docker images to repository"
	@echo "  observe   			- Run the observer script"
	@echo "  analyze   			- Run the analyzer script"
	@echo "  plot      			- Run the plotter script"
	@echo "  wrap      			- Run the wrapper script"
	@echo "  jitter-perf		- Run jitter performance test"
	@echo "  jitter-obs			- Run jitter observation test"
	@echo "  dummy-perf			- Run dummy performance test"
	@echo "  dummy-obs			- Run dummy observation test"
	@echo "  jitterdummy-perf	- Run jitter+dummy performance test"
	@echo "  jitterdummy-obs	- Run jitter+dummy observation test"
	
	@echo "  help     			- Show this help message"