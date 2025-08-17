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


(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NICKNAME".tor.log