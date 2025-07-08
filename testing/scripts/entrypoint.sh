#!/bin/bash
HOST=$(hostname)
NICKNAME=$(echo $HOST | tr -d '-')

echo "Starting DPTOR node with nickname: $NICKNAME"
echo "Hostname: $HOST"

mkdir -p /app/logs/tor
mkdir -p /app/logs/wireshark/$NICKNAME
mkdir -p /app/conf

cp /app/conf/nodes/"$RELAY_TYPE"/torrc /app/tor/torrc

if [ "$RELAY_TYPE" != "client" ]; then
    cp -r /app/conf/nodes/"$RELAY_TYPE"/crypto/* /app/tor/
fi

cd /app/tor || exit 1

sed -i "s/^Address .*/Address $HOST/" /app/conf/tor.common.torrc
sed -i "s/^Nickname .*/Nickname $NICKNAME/" /app/conf/tor.common.torrc

cat /app/conf/tor.common.torrc 

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NICKNAME".tor.log
