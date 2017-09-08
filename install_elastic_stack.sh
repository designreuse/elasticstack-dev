#!/bin/bash

PWD=`pwd`

ESGR=`grep elasticstack /etc/group`
if [ "x$ESGR" == "x" ]; then
  groupadd elasticstack
fi;

# ******** ELASTICSEARCH
echo "++ Installing Elasticsearch..."
USER_EXISTS=`getent passwd | grep elasticsearch`

if [ "x$USER_EXISTS" == "x" ]; then
  useradd -r -g elasticstack --no-create-home  elasticsearch
fi;

if [ -e elasticsearch-5.5.0.zip ]; then
  echo 'Skipping download of elasticsearch-5.5.0.zip, file exists'
else
  wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.0.zip
fi;

unzip -q elasticsearch-5.5.0.zip
mv elasticsearch-5.5.0 elasticsearch

chown -R elasticsearch:elasticstack elasticsearch

export ES_NETWORK_HOST=0.0.0.0
sed -i -e 's/#network.host: 192.168.0.1/#network.host: \${ES_NETWORK_HOST}/g' elasticsearch/config/elasticsearch.yml
sysctl -w vm.max_map_count=262144 > /dev/null

su - elasticsearch -c "$PWD/elasticsearch/bin/elasticsearch -d" > /dev/null
echo "-- Finished Elasticsearch installation and running"

# ********** ZOOKEEPER
echo "++ Installing Zookeeper..."
USER_EXISTS=`getent passwd | grep zookeeper`

if [ "x$USER_EXISTS" == "x" ]; then
  useradd -r -g elasticstack --no-create-home zookeeper
fi;

if [ -e zookeeper-3.4.10.tar.gz ]; then
  echo 'Skipping download of zookeeper-3.4.10.tar.gz, file exists'
else
  wget http://ftp.unicamp.br/pub/apache/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
fi;

tar xfz zookeeper-3.4.10.tar.gz

mv zookeeper-3.4.10 zookeeper
mv zookeeper/conf/zoo_sample.cfg zookeeper/conf/zoo.cfg
mkdir zookeeper/logs zookeeper/datadir -p

sed -i -e "s|dataDir=/tmp/zookeeper|dataDir=$PWD/zookeeper/datadir|g" zookeeper/conf/zoo.cfg

chown -R zookeeper:elasticstack zookeeper

su - zookeeper -c "export ZOO_LOG_DIR=$PWD/zookeeper/logs; $PWD/zookeeper/bin/zkServer.sh start" > /dev/null
echo "-- Finished Zookeeper installation and running"

# +++++++ KAFKA
echo "++ Installing Kafka..."
USER_EXISTS=`getent passwd | grep kafka`

if [ "x$USER_EXISTS" == "x" ]; then
  useradd -r -g elasticstack --no-create-home kafka
fi;

if [ -e kafka_2.12-0.11.0.0.tgz ]; then
  echo 'Skipping download of kafka_2.12-0.11.0.0.tgz, file exists'
else
  wget http://ftp.unicamp.br/pub/apache/kafka/0.11.0.0/kafka_2.12-0.11.0.0.tgz
fi;

tar xfz kafka_2.12-0.11.0.0.tgz
mv kafka_2.12-0.11.0.0 kafka

mkdir kafka/logfiles -p
sed -i -e "s|log.dirs=/tmp/kafka-logs|log.dirs=$PWD/kafka/logfiles|g" kafka/config/server.properties
sed -i -e "s|#listeners=PLAINTEXT://:9092|PLAINTEXT://0.0.0.0:9092|g" kafka/config/server.properties

chown -R kafka:elasticstack kafka

su - kafka -c "$PWD/kafka/bin/kafka-server-start.sh -daemon $PWD/kafka/config/server.properties" > /dev/null

echo "   Waiting Kafka start: "
for i in $(seq 1 10); do
  echo -n "x"
  F=`grep 'started (kafka.server.KafkaServer)' $PWD/kafka/logs/server.log`
  if [ "x$F" == "x" ]; then
    sleep 1;
  fi;
done;
echo "."

echo "   Creating Kafka topic"
su - kafka -c "$PWD/kafka/bin/kafka-topics.sh --create --zookeeper localhost:2181 --replication-factor 1 --partitions 1 --topic elasticsearch-lane" > /dev/null
echo "-- Finished Kafka installation and running"

# ++++++++ LOGSTASH
echo "++ Installing Logstash..."
USER_EXISTS=`getent passwd | grep logstash`

if [ "x$USER_EXISTS" == "x" ]; then
  useradd -r -g elasticstack --no-create-home logstash
fi;

if [ -e logstash-5.5.0.tar.gz ]; then
  echo 'Skipping download of logstash-5.5.0.tar.gz, file exists'
else
  wget https://artifacts.elastic.co/downloads/logstash/logstash-5.5.0.tar.gz
fi;

tar xfz logstash-5.5.0.tar.gz
mv logstash-5.5.0 logstash
# fonte: https://gist.github.com/trestini/08119a65cf20b48793c2cdc38d5cf6b8
curl -s https://gist.githubusercontent.com/trestini/08119a65cf20b48793c2cdc38d5cf6b8/raw > $PWD/logstash/pipeline.conf
sed -i -e "s|stdout { codec => rubydebug }| |g" $PWD/logstash/pipeline.conf

chown -R logstash:elasticstack logstash 

su - logstash -c "/usr/bin/nohup $PWD/logstash/bin/logstash --log.level warn -f $PWD/logstash/pipeline.conf > $PWD/logstash/logstash.log &" > /dev/null
echo "-- Finished Logstash installation and running"

# ++++++++ KIBANA
echo "++ Installing Kibana..."
USER_EXISTS=`getent passwd | grep kibana`

if [ "x$USER_EXISTS" == "x" ]; then
  useradd -r -g elasticstack --no-create-home kibana 
fi;

if [ -e kibana-5.5.0-linux-x86_64.tar.gz ]; then
  echo 'Skipping download of kibana-5.5.0-linux-x86_64.tar.gz, file exists'
else
  wget https://artifacts.elastic.co/downloads/kibana/kibana-5.5.0-linux-x86_64.tar.gz
fi;

tar xfz kibana-5.5.0-linux-x86_64.tar.gz
mv kibana-5.5.0-linux-x86_64 kibana
sed -i -e 's|#server.host: "localhost"|server.host: "0.0.0.0"|g' $PWD/kibana/config/kibana.yml
sed -i -e 's|#server.port: 5601|server.port: 8080|g' $PWD/kibana/config/kibana.yml

chown -R kibana:elasticstack kibana

su - kibana -c "/usr/bin/nohup $PWD/kibana/bin/kibana > $PWD/kibana/kibana.log &" > /dev/null
sleep 1;
echo "-- Finished Kibana installation and running"
