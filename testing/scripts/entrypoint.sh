#!/bin/bash
HOST=$(hostname)
IP_ADDRESS=$(hostname -i)
NICKNAME=$(echo $HOST | tr -d '-')

if [ "$RELAY_TYPE" == "authority" ]; then
    sed -i "s/DirAuthority .*/DirAuthority authority orport=9001 v3ident=251A6199439061376DBDEB65848324E2D5EC89C7 ${IP_ADDRESS}:9030 A52CA5B56C64D864F6AE43E56F29ACBD5706DDA1/" /app/conf/tor.common.torrc
else
    sleep 10
fi

mkdir -p /app/logs/tor
mkdir -p /app/logs/wireshark/$NICKNAME
mkdir -p /app/conf

cp /app/conf/nodes/"$RELAY_TYPE"/torrc /app/tor/torrc

sed -i "s/^Address .*/Address $IP_ADDRESS/" /app/conf/tor.common.torrc
sed -i "s/^Nickname .*/Nickname $NICKNAME/" /app/conf/tor.common.torrc

if [ "$RELAY_TYPE" != "client" ]; then
    cp -r /app/conf/nodes/$RELAY_TYPE/crypto/* /app/tor/
fi

cd /app/tor || exit 1

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NICKNAME".tor.log
