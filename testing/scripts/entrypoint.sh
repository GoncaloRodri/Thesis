#!/bin/bash
HOST=$(hostname)
NICKNAME=$(echo $HOST | tr -d '-')

echo "Starting DPTOR node with nickname: $NICKNAME"
echo "Hostname: $HOST"

mkdir -p /app/logs/tor
mkdir -p /app/logs/wireshark/$NICKNAME
mkdir -p /app/conf

cp /app/conf/nodes/"$RELAY_TYPE"/torrc /app/tor/torrc

if [ "$RELAY_TYPE" != "authority" ]; then
    AUTHORITY_IP=$(getent hosts authority | awk '{ print $1 }')
    sed -i "s/DirAuthority .*/DirAuthority authority orport=9001 v3ident=251A6199439061376DBDEB65848324E2D5EC89C7 ${AUTHORITY_IP}:9030 A52CA5B56C64D864F6AE43E56F29ACBD5706DDA1/" /app/conf/tor.common.torrc
fi

cd /app/tor || exit 1

sed -i "s/^Address .*/Address $HOST/" /app/conf/tor.common.torrc
sed -i "s/^Nickname .*/Nickname $NICKNAME/" /app/conf/tor.common.torrc

cat /app/conf/tor.common.torrc

(tor -f /app/tor/torrc) | tee /app/logs/tor/"$NICKNAME".tor.log
