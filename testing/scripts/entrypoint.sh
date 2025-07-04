#!/bin/bash

mkdir -p /app/logs/tor
mkdir -p /app/logs/wireshark/"$RELAY_TYPE"
mkdir -p /app/conf

cp /app/conf/nodes/"$RELAY_TYPE"/torrc /app/tor/torrc

if [ "$RELAY_TYPE" != "client" ]; then
    cp -r /app/conf/nodes/"$RELAY_TYPE"/crypto/* /app/tor/
fi

if [ "$RELAY_TYPE" = "hidden_service" ]; then
    mkdir -p /root/.tor/hidden_service
    cp -r /app/hidden_service/* /root/.tor/hidden_service/
fi

cd /app/tor || exit 1

sed -i "s/^Address .*/Address $(hostname -i)/" /app/conf/tor.common.torrc
sed -i "s/^Nickname .*/Nickname $NAME/" /app/conf/tor.common.torrc

cat /app/conf/tor.common.torrc 

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NAME".tor.log
