nodes=(
    authority
    relay1
    relay2
    exit1
    client
)

total=0

for node in "${nodes[@]}"; do
    echo "Checking bootstrapping status on $node..."
    count=$(ssh $node "sh -c 'grep -l -R \"Bootstrapped 100%\" ~/Thesis/testing/logs/tor/*' | wc -l")
    echo $count
    total=$((total + count))
done

echo "Total bootstrapped nodes: $total"
