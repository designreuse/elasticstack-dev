#!/bin/bash

echo "Java's..."
pkill java

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
