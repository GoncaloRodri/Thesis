#!/bin/bash
HOST=$(hostname)
IP_ADDRESS=$(hostname -i)
NICKNAME=$(echo $HOST | tr -d '-')

echo "================================================================================"
echo "Starting Tor with the following configuration:"
echo "HOSTNAME: $HOST"
echo "IP_ADDRESS: $IP_ADDRESS"
echo "NICKNAME: $NICKNAME"
echo "RELAY_TYPE: $RELAY_TYPE"
echo "================================================================================"


if [ "$RELAY_TYPE" == "authority" ]; then
    sed -i "s/DirAuthority .*/DirAuthority authority orport=9001 v3ident=251A6199439061376DBDEB65848324E2D5EC89C7 ${IP_ADDRESS}:9030 A52CA5B56C64D864F6AE43E56F29ACBD5706DDA1/" /app/conf/tor.common.torrc
else
    echo "================================================================================"
    sleep 10
    echo "Waiting for authority to be ready..."
fi

mkdir -p /app/logs/tor
mkdir -p /app/logs/wireshark/$NICKNAME
mkdir -p /app/conf

if [ ! -d /app/conf/nodes/"$NICKNAME" ]; then
    mkdir -p /app/conf/nodes/"$NICKNAME"
    cp /app/conf/nodes/"${RELAY_TYPE}"/torrc /app/conf/nodes/"$NICKNAME"/
fi

sed -i "s/^Address .*/Address $IP_ADDRESS/" /app/conf/nodes/"$NICKNAME"/torrc
sed -i "s/^Nickname .*/Nickname $NICKNAME/" /app/conf/nodes/"$NICKNAME"/torrc
wait 

cp /app/conf/nodes/"$NICKNAME"/torrc /app/tor/torrc

if [ "$RELAY_TYPE" != "client" ]; then
    cp -r /app/conf/nodes/"$NICKNAME"/crypto/* /app/tor/
fi

cd /app/tor || exit 1
echo "================================================================================"
echo
echo "NICKNAME: $NICKNAME"
echo "IP_ADDRESS: $IP_ADDRESS"

cat /app/tor/torrc

echo
echo "================================================================================"
echo

if [ "$RELAY_TYPE" == "authority" ]; then
    sleep 10
fi

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NICKNAME".tor.log