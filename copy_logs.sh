nodes=(
    authority
    relay1
    relay2
    exit1
    client
)

for node in "${nodes[@]}"; do
    scp -r "$node:~/Thesis/testing/logs/tor/" "/home/guga/Documents/Thesis/testing/logs/"
done