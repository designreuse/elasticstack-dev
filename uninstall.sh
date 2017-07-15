#!/bin/bash

echo "Java's..."
if [ -e kafka/bin/kafka-server-stop.sh ]; then
  kafka/bin/kafka-server-stop.sh
fi; 
pkill java
pkill logstash
pkill node

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

echo Logstash...
rm -rf logstash
userdel logstash

echo Kibana...
rm -rf kibana
userdel kibana

echo Finalizando...
groupdel elasticstack


echo 'Fim =)'
