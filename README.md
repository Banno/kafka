Kafka Mesos Framework
======================

This is a *beta* version. For issues https://github.com/mesos/kafka/issues

[Installation](#installation)    
* [Environment Configuration](#environment-configuration)
* [Scheduler Configuration](#scheduler-configuration)
* [Run the scheduler](#run-the-scheduler)
* [Starting and using 1 broker](#starting-and-using-1-broker)

[Typical Operations](#typical-operations)
* [Run the scheduler with Docker](https://github.com/Banno/kafka/blob/gradle-docker/DOCKER.md)
* [Run the scheduler on Marathon](https://github.com/Banno/kafka/blob/gradle-docker/DOCKER.md#running-image-in-marathon)
* [Changing the location of data stored](#changing-the-location-of-data-stored)
* [Starting 3 brokers](#starting-3-brokers)
* [High Availability Scheduler State](#high-availability-scheduler-state)
* [Failed Broker Recovery](#failed-broker-recovery)


[Navigating the CLI](#navigating-the-cli)
* [Adding brokers to the cluster](#adding-brokers-to-the-cluster)
* [Updating broker configurations](#updating-the-broker-configurations)
* [Starting brokers](#starting-brokers-in-the-cluster-)
* [Stopping brokers](#stopping-brokers-in-the-cluster)
* [Removing brokers](#removing-brokers-from-the-cluster)
* [Rebalancing brokers in the cluster](#rebalancing-brokers-in-the-cluster)

[Using the REST API](#using-the-rest-api)    

[Project Goals](#project-goals)

Installation
-------------

Install OpenJDK 7 (or higher) http://openjdk.java.net/install/

Install gradle http://gradle.org/installation

Clone and build the project

    # git clone https://github.com/mesos/kafka
    # cd kafka
    # ./gradlew jar
    # wget https://archive.apache.org/dist/kafka/0.8.2.1/kafka_2.10-0.8.2.1.tgz

Environment Configuration
--------------------------

Before running `./kafka-mesos.sh`, set the location of libmesos:

    # export MESOS_NATIVE_JAVA_LIBRARY=/usr/local/lib/libmesos.so

If the host running scheduler has several IP addresses you may also need to

    # export LIBPROCESS_IP=<IP_ACCESSIBLE_FROM_MASTER>

Scheduler Configuration
----------------------

The scheduler is configured through the command line or `kafka-mesos.properties` file.

Following options are available:
```
# ./kafka-mesos.sh help scheduler
Start scheduler 
Usage: scheduler [options] [config.properties]

Option               Description                           
------               -----------                           
--api                Api url. Example: http://master:7000  
--debug <Boolean>    Debug mode. Default - false           
--framework-name     Framework name. Default - kafka       
--framework-role     Framework role. Default - *           
--framework-timeout  Framework timeout (30s, 1m, 1h).      
                       Default - 30d
--master             Master connection settings. Examples:
                      - master:5050
                      - master:5050,master2:5050
                      - zk://master:2181/mesos
                      - zk://username:password@master:2181
                      - zk://master:2181,master2:2181/mesos
--principal          Principal (username) used to register
                       framework. Default - none
--secret             Secret (password) used to register
                       framework. Default - none
--storage            Storage for cluster state. Examples:
                      - file:kafka-mesos.json
                      - zk:/kafka-mesos
                     Default - file:kafka-mesos.json
--user               Mesos user to run tasks. Default -
                       current system user
--zk                 Kafka zookeeper.connect. Examples:
                      - master:2181
                      - master:2181,master2:2181
```

Additionally you can create `kafka-mesos.properties` containing values for CLI options of scheduler.

Example of `kafka-mesos.properties`:
```
storage=file:kafka-mesos.json
master=zk://master:2181/mesos
zk=master:2181
api=http://master:7000
```

Now if running scheduler via `./kafka-mesos.sh scheduler` (no options specified) the scheduler will read values for options
from the above file. You could also specify alternative config file by using `config` argument of the scheduler.

Run the scheduler
-----------------

Start the Kafka scheduler using this command:

    # ./kafka-mesos.sh scheduler

Note: you can also use Marathon to launch the scheduler process so it gets restarted if it crashes.

Starting and using 1 broker
---------------------------

First lets start up and use 1 broker with the default settings. Further in the readme you can see how to change these from the defaults.

```
# ./kafka-mesos.sh add 0
Broker added

broker:
  id: 0
  active: false
  state: stopped
  resources: cpus:1.00, mem:2048, heap:1024, port:auto
  failover: delay:10s, max-delay:60s
```

You now have a cluster with 1 broker that is not started.

```
# ./kafka-mesos.sh status
Cluster status received

cluster:
  brokers:
    id: 0
    active: false
    state: stopped
    resources: cpus:1.00, mem:2048, heap:1024, port:auto
    failover: delay:10s, max-delay:60s
```
Now lets start the broker.

```
# ./kafka-mesos.sh start 0
Broker 0 started
```

Now, we don't know where the broker is and we need that for producers and consumers to connect to the cluster.

```
# ./kafka-mesos.sh status
Cluster status received

cluster:
  brokers:
    id: 0
    active: true
    state: running
    resources: cpus:1.00, mem:2048, heap:1024, port:auto
    failover: delay:10s, max-delay:60s
    task:
      id: broker-0-d2d94520-2f3e-4779-b276-771b4843043c
      running: true
      endpoint: 172.16.25.62:31000
      attributes: rack=r1
```

Great!!! Now lets produce and consume from the cluster. Lets use [kafkacat](https://github.com/edenhill/kafkacat) a nice third party c library command line tool for Kafka.

```
# echo "test"|kafkacat -P -b "172.16.25.62:31000" -t testTopic -p 0
```

And lets read it back.

```
# kafkacat -C -b "172.16.25.62:31000" -t testTopic -p 0 -e
test
```

This is an beta version.

Typical Operations
===================

Changing the location of data stored
-------------------------------------

```
# ./kafka-mesos.sh stop 0
Broker 0 stopped
# ./kafka-mesos.sh update 0 --options log.dirs=/mnt/array1/broker0
Broker updated

broker:
  id: 0
  active: false
  state: stopped
  resources: cpus:1.00, mem:2048, heap:1024, port:auto
  options: log.dirs=/mnt/array1/broker0
  failover: delay:1m, max-delay:10m
  stickiness: period:10m, hostname:slave0, expires:2015-07-10 15:51:43+03

# ./kafka-mesos.sh start 0
Broker 0 started
```

Starting 3 brokers
-------------------------

```
#./kafka-mesos.sh add 0..2 --heap 1024 --mem 2048
Brokers added

brokers:
  id: 0
  active: false
  state: stopped
  resources: cpus:1.00, mem:2048, heap:1024, port:auto
  failover: delay:1m, max-delay:10m
  stickiness: period:10m, hostname:slave0, expires:2015-07-10 15:51:43+03

  id: 1
  active: false
  state: stopped
  resources: cpus:1.00, mem:2048, heap:1024, port:auto
  failover: delay:1m, max-delay:10m
  stickiness: period:10m, hostname:slave1, expires:2015-07-10 15:51:43+03

  id: 2
  active: false
  state: stopped
  resources: cpus:1.00, mem:2048, heap:1024, port:auto
  failover: delay:1m, max-delay:10m
  stickiness: period:10m, hostname:slave2, expires:2015-07-10 15:51:43+03

#./kafka-mesos.sh start 0
Broker 0 started
#./kafka-mesos.sh start 1
Broker 1 started
#./kafka-mesos.sh start 2
Broker 2 started
```

High Availability Scheduler State
-------------------------
The scheduler supports storing the state of the cluster in Zookeeper. It currently shares a znode within the mesos ensemble. To turn this on in properties 

```
clusterStorage=zk:/kafka-mesos
```

Failed Broker Recovery
------------------------
When the broker fails, kafka mesos scheduler assumes that the failure is recoverable. Scheduler will try
to restart broker after waiting failover-delay (i.e. 30s, 2m). Initially waiting delay is equal to failover-delay setting.
After each serial failure it doubles until it reaches failover-max-delay value.

If failover-max-tries is defined and serial failure count exceeds it, broker will be deactivated.

Following failover settings exists:
```
--failover-delay     - initial failover delay to wait after failure, required
--failover-max-delay - max failover delay, required
--failover-max-tries - max failover tries to deactivate broker, optional
```

Broker Placement Stickiness
---------------------------
If broker is started during stickiness-period time from it's stop time, scheduler will place the broker on the same node
as it was during last successful start. This is related both to failover and manual restarts.

Following stickiness settings exists:
```
--stickiness-period  - period of time during which broker would be restarted on the same node
```

Navigating the CLI
==================

Adding brokers to the cluster
-------------------------------

```
# ./kafka-mesos.sh help add
Add broker
Usage: add <id-expr> [options]

Option                Description
------                -----------
--bind-address        broker bind address (broker0, 192.168.50.*, if:eth1). Default - auto
--constraints         constraints (hostname=like:master,rack=like:1.*). See below.
--cpus <Double>       cpu amount (0.5, 1, 2)
--failover-delay      failover delay (10s, 5m, 3h)
--failover-max-delay  max failover delay. See failoverDelay.
--failover-max-tries  max failover tries. Default - none
--heap <Long>         heap amount in Mb
--jvm-options         jvm options string (-Xms128m -XX:PermSize=48m)
--log4j-options       log4j options or file. Examples:
                       log4j.logger.kafka=DEBUG\, kafkaAppender
                       file:log4j.properties
--mem <Long>          mem amount in Mb
--options             options or file. Examples:
                       log.dirs=/tmp/kafka/$id,num.io.threads=16
                       file:server.properties
--port                port or range (31092, 31090..31100). Default - auto
--stickiness-period   stickiness period to preserve same node for broker (5m, 10m, 1h)

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker

constraint examples:
  like:master     - value equals 'master'
  unlike:master   - value not equals 'master'
  like:slave.*    - value starts with 'slave'
  unique          - all values are unique
  cluster         - all values are the same
  cluster:master  - value equals 'master'
  groupBy         - all values are the same
  groupBy:3       - all values are within 3 different groups
```

Updating broker configurations
-----------------------------------

```
# ./kafka-mesos.sh help update
Update broker
Usage: update <id-expr> [options]

Option                Description
------                -----------
--bind-address        broker bind address (broker0, 192.168.50.*, if:eth1). Default - auto
--constraints         constraints (hostname=like:master,rack=like:1.*). See below.
--cpus <Double>       cpu amount (0.5, 1, 2)
--failover-delay      failover delay (10s, 5m, 3h)
--failover-max-delay  max failover delay. See failoverDelay.
--failover-max-tries  max failover tries. Default - none
--heap <Long>         heap amount in Mb
--jvm-options         jvm options string (-Xms128m -XX:PermSize=48m)
--log4j-options       log4j options or file. Examples:
                       log4j.logger.kafka=DEBUG\, kafkaAppender
                       file:log4j.properties
--mem <Long>          mem amount in Mb
--options             options or file. Examples:
                       log.dirs=/tmp/kafka/$id,num.io.threads=16
                       file:server.properties
--port                port or range (31092, 31090..31100). Default - auto
--stickiness-period   stickiness period to preserve same node for broker (5m, 10m, 1h)

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker

constraint examples:
  like:master     - value equals 'master'
  unlike:master   - value not equals 'master'
  like:slave.*    - value starts with 'slave'
  unique          - all values are unique
  cluster         - all values are the same
  cluster:master  - value equals 'master'
  groupBy         - all values are the same
  groupBy:3       - all values are within 3 different groups

Note: use "" arg to unset an option
```

Starting brokers in the cluster
-------------------------------

```
# ./kafka-mesos.sh help start
Start broker
Usage: start <id-expr> [options]

Option     Description
------     -----------
--timeout  timeout (30s, 1m, 1h). 0s - no timeout

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker
```

Stopping brokers in the cluster
-------------------------------

```
# ./kafka-mesos.sh help stop
Stop broker
Usage: stop <id-expr> [options]

Option     Description
------     -----------
--force    forcibly stop
--timeout  timeout (30s, 1m, 1h). 0s - no timeout

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker
```

Removing brokers from the cluster
----------------------------------

```
# ./kafka-mesos.sh help remove
Remove broker
Usage: remove <id-expr> [options]

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker
```

Rebalancing brokers in the cluster
----------------------------------
```
# ./kafka-mesos.sh help rebalance
Rebalance
Usage: rebalance <id-expr>|status [options]

Option     Description
------     -----------
--timeout  timeout (30s, 1m, 1h). 0s - no timeout
--topics   <topic-expr>. Default - *. See below.

Generic Options
Option  Description
------  -----------
--api   Api url. Example: http://master:7000

topic-expr examples:
  t0        - topic t0 with default RF (replication-factor)
  t0,t1     - topics t0, t1 with default RF
  t0:3      - topic t0 with RF=3
  t0,t1:2   - topic t0 with default RF, topic t1 with RF=2
  *         - all topics with default RF
  *:2       - all topics with RF=2
  t0:1,*:2  - all topics with RF=2 except topic t0 with RF=1

id-expr examples:
  0      - broker 0
  0,1    - brokers 0,1
  0..2   - brokers 0,1,2
  0,1..2 - brokers 0,1,2
  *      - any broker
```

Using the REST API
========================

The scheduler REST API fully exposes all features of the CLI using following request format:
```
/api/brokers/<cli command>/id={broker.id}&<setting>=<value>
```

Adding a broker

```
# curl "http://localhost:7000/api/brokers/add?id=0&cpus=8&mem=43008"
{"brokers" : [{"id" : "0", "mem" : 43008, "cpus" : 8.0, "heap" : 128, "failover" : {"delay" : "10s", "maxDelay" : "60s"}, "active" : false}]}
```

Starting a broker

```
# curl "http://localhost:7000/api/brokers/start?id=0"
{"success" : true, "ids" : "0"}
```

Stopping a broker

```
# curl "http://localhost:7000/api/brokers/stop?id=0"
{"success" : true, "ids" : "0"}
```

Status

```
# curl "http://localhost:7000/api/brokers/status?id=0"
{"brokers" : [{"id" : "0", "mem" : 128, "cpus" : 0.1, "heap" : 128, "failover" : {"delay" : "10s", "maxDelay" : "60s", "failures" : 5, "failureTime" : 1426651240585}, "active" : true}, {"id" : "5", "mem" : 128, "cpus" : 0.5, "heap" : 128, "failover" : {"delay" : "10s", "maxDelay" : "60s"}, "active" : false}, {"id" : "8", "mem" : 43008, "cpus" : 8.0, "heap" : 128, "failover" : {"delay" : "10s", "maxDelay" : "60s"}, "active" : true}]}
```

Project Goals
==============

* smart broker.id assignment.

* preservation of broker placement (through constraints and/or new features).

* ability to-do configuration changes.

* rolling restarts (for things like configuration changes).

* scaling the cluster up and down with automatic, programmatic and manual options.

* smart partition assignment via constraints visa vi roles, resources and attributes.
