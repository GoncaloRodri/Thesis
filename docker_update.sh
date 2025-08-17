nodes=(
    authority
    relay1
    relay2
    exit1
    client
)

docker buildx build \
    -t gugarodri/dptor_base \
    -f testing/docker/base.Dockerfile \
    .
docker buildx build \
    -t gugarodri/dptor_httpserver \
    -f testing/docker/httpserver.Dockerfile \
    .
docker buildx build \
    -t gugarodri/dptor_swarm \
    -f testing/docker/swarm.Dockerfile \
        .

docker push gugarodri/dptor_base
docker push gugarodri/dptor_httpserver
docker push gugarodri/dptor_swarm

for node in "${nodes[@]}"; do
    ssh "$node" "docker pull gugarodri/dptor_httpserver"
    ssh "$node" "docker pull gugarodri/dptor_swarm"
done