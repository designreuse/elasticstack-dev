#!/bin/bash

echo "Java's..."
kafka/bin/kafka-server-stop.sh
pkill java

sleep 3

pkill -9 java

echo Elasticsearch...
rm -rf elasticsearch
userdel elasticsearch

echo Zookeeper...
rm -rf zookeeper
userdel zookeeper

echo Kafka...
rm -rf kafka
userdel kafka

echo Finalizando...
groupdel elasticstack


echo 'Fim =)'
