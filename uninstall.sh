#!/bin/bash

echo "Java's..."
pkill java

echo Elasticsearch...
rm -rf elasticsearch
userdel elasticsearch

echo Zookeeper...
rm -rf zookeeper
userdel zookeeper

echo Finalizando...
groupdel elasticstack


echo 'Fim =)'
