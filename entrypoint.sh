#!/bin/bash

if [ "$(whoami)" == "root" ]; then
  # Fix if the container is launched with the root (host) user
  if [ $HOST_UID -eq 0 ]; then
    HOST_UID=1000
  fi

  useradd -s /bin/bash -u $HOST_UID tor 2> /dev/null

  if [ $? -eq 0 ]; then
    echo -e "export NICKNAME='${NICKNAME:-NotProvided}'\n\
    export CONTACT_INFO='${CONTACT_INFO:-NotProvided}'\n\
    export OR_PORT='${OR_PORT:-9001}'\n\
    export DIR_PORT='${DIR_PORT:-9030}'\n\
    export CONTROL_PORT='${CONTROL_PORT:-9051}'\n\
    export BANDWIDTH_RATE='${BANDWIDTH_RATE:-1 MBits}'\n\
    export BANDWIDTH_BURST='${BANDWIDTH_BURST:-2 MBits}'\n\
    export MAX_MEM='${MAX_MEM:-512 MB}'\n\
    export ACCOUNTING_MAX='${ACCOUNTING_MAX:-0}'\n\
    export ACCOUNTING_START='${ACCOUNTING_START:-month 1 00:00}'" > /home/tor/env.sh \
    && chown -R tor:tor /home/tor
  fi

  su -c "/entrypoint.sh $1" - tor
  exit
fi

CONF_FILE=/home/tor/torrc
source ~/env.sh

echo -e "SocksPort 0\n\
DataDirectory /home/tor/data\n\
DisableDebuggerAttachment 0\n\
ControlPort $CONTROL_PORT\n\
Nickname $NICKNAME\n\
ContactInfo $CONTACT_INFO\n\
RelayBandwidthRate $BANDWIDTH_RATE\n\
RelayBandwidthBurst $BANDWIDTH_BURST\n\
MaxMemInQueues $MAX_MEM\n\
AccountingMax $ACCOUNTING_MAX\n\
AccountingStart $ACCOUNTING_START" > $CONF_FILE

for PORT in $OR_PORT; do
  echo -e "ORPort $PORT" >> $CONF_FILE
done

if [ "$1" == "middle" ]; then
  echo -e "ExitRelay 0\n\
ExitPolicy reject *:*\n\
DirPort $DIR_PORT" >> $CONF_FILE
fi

if [ "$1" == "bridge" ]; then
  echo -e "ExitRelay 0\n\
ExitPolicy reject *:*\n\
BridgeRelay 1" >> $CONF_FILE
fi

if [ "$1" == "exit" ]; then
  echo -e "DirPort $DIR_PORT\n\
ExitPolicy reject 0.0.0.0/8:*\n\
ExitPolicy reject 10.0.0.0/8:*\n\
ExitPolicy reject 44.128.0.0/16:*\n\
ExitPolicy reject 127.0.0.0/8:*\n\
ExitPolicy reject 192.168.0.0/16:*\n\
ExitPolicy reject 169.254.0.0/15:*\n\
ExitPolicy reject 172.16.0.0/12:*\n\
ExitPolicy reject 62.141.55.117:*\n\
ExitPolicy reject 62.141.54.117:*\n\
ExitPolicy accept *:*" >> $CONF_FILE
fi

cat $CONF_FILE

exec /usr/local/bin/tor -f ~/torrc
