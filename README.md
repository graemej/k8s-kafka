# k8s-kafka

Docker container to run `kafka` (0.8.1.1) in an Ubuntu container (java7) with configuration settings from the environment.

## environment

The names of these environment variables are carefully chosen for compatibility with what Kubernetes (primarily GKE) provides for defined services.

* `KAFKA_SERVER_ID`: required, integer 1..cluster size
* for each Kafka instance in the cluster
  * `KAFKA_CLIENT_<i>_SERVICE_HOST`: IP address of the etcd instance
  * `KAFKA_CLIENT_<i>_SERVICE_PORT`: port number of the etcd client service (4001)
* for each Zookeeper instance
  * `ZK_CLIENT_<i>_SERVICE_HOST`: IP address of the Zookeeper instance
  * `ZK_CLIENT_<i>_SERVICE_PORT`: port number of the Zookeeper client service

## notes

To start a two node cluster, run this first to start zookeeper:

```
env HOST_IP=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"` \
 docker run \
  -P \
  -e ZK_SERVER_ID=1 \
  -e ZK_CLIENT_SERVICE_PORT=2181 \
  -e ZK_CLIENT_1_SERVICE_HOST=${HOST_IP} \
  -e ZK_CLIENT_1_SERVICE_PORT=2181 \
  -e ZK_PEER_1_SERVICE_HOST=${HOST_IP} \
  -e ZK_PEER_1_SERVICE_PORT=2888 \
  -e ZK_ELECTION_1_SERVICE_HOST=${HOST_IP} \
  -e ZK_ELECTION_1_SERVICE_PORT=3888 \
  fabric8/zookeeper
```

Now bring up the first Kafka node:

```
docker run \
 -P \
 -e KAFKA_SERVER_ID=1 \
 -e KAFKA_CLIENT_1_SERVICE_HOST=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"` \
 -e KAFKA_CLIENT_1_SERVICE_PORT=9093 \
 -e ZK_CLIENT_1_SERVICE_HOST=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"` \
 -e ZK_CLIENT_1_SERVICE_PORT=2181 \
 graemej/k8s-kafka
```

and the second Kafka node:

```
docker run \
 -P \
 -e KAFKA_SERVER_ID=2 \
 -e KAFKA_CLIENT_2_SERVICE_HOST=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"` \
 -e KAFKA_CLIENT_2_SERVICE_PORT=9094 \
 -e ZK_CLIENT_1_SERVICE_HOST=`ip ro get 8.8.8.8 | grep -oP "(?<=src )(\S+)"` \
 -e ZK_CLIENT_1_SERVICE_PORT=2181 \
 graemej/k8s-kafka
```
