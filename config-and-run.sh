#!/bin/bash

function getKey() {
  echo $1 | cut -d "=" -f1
}

function getValue() {
  echo $1 | cut -d "=" -f2
}

function envValue() {
 local entry=`env | grep $1`
 echo `getValue $entry`
}

set -ex

#Find the server id
SERVER_ID=`envValue KAFKA_SERVER_ID`
if [ ! -z "$SERVER_ID" ] ; then
  export ADVERTISED_HOST_NAME=`envValue KAFKA_CLIENT_${SERVER_ID}_SERVICE_HOST`
  export ADVERTISED_PORT=`envValue KAFKA_CLIENT_${SERVER_ID}_SERVICE_PORT`

  # Find the zookeepers exposed in env.
  ZOOKEEPER_CONNECT=""
  for i in `echo {1..15}`; do
    ZK_CLIENT_HOST=`envValue ZK_CLIENT_${i}_SERVICE_HOST`
    ZK_CLIENT_PORT=`envValue ZK_CLIENT_${i}_SERVICE_PORT`

    if [ -z "$ZK_CLIENT_HOST" ] || [ -z "$ZK_CLIENT_PORT" ] ; then
      break
    else
      if [ ! -z $ZOOKEEPER_CONNECT ] ; then
        ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT},"
      fi
      ZOOKEEPER_CONNECT="${ZOOKEEPER_CONNECT}${ZK_CLIENT_HOST}:${ZK_CLIENT_PORT}"
    fi
  done
fi

# Build the server configuration
cat /kafka/config/server.properties \
  | sed "s|{{BROKER_ID}}|${KAFKA_SERVER_ID}|g" \
  | sed "s|{{ADVERTISED_HOST_NAME}}|${ADVERTISED_HOST_NAME}|g" \
  | sed "s|{{ADVERTISED_PORT}}|${ADVERTISED_PORT}|g" \
  | sed "s|{{ZOOKEEPER_CONNECT}}|${ZOOKEEPER_CONNECT}|g" \
    > /kafka/config/server.properties

export CLASSPATH=$CLASSPATH:/kafka/lib/slf4j-log4j12.jar
export JMX_PORT=7203

cat /kafka/config/server.properties

echo "Starting kafka"
exec /kafka/bin/kafka-server-start.sh /kafka/config/server.properties
