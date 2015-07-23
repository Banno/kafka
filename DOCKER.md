# Intro
A docker image can be built with gradle.

The image will have following pre-installed components:
- openjdk-jdk;
- mesos native libs;

`/opt/kafka-mesos` folder will contain following content:
- kafka*.tgz - kafka distro;
- kafka-mesos*.jar - kafka-mesos distro;
- kafka-mesos.sh - shell script to run kafka-mesos;

No default configuration file for kafka-mesos is provided. All configuration params should be
specified via cli options.

# Building image
Building docker image is done by the [gradle-docker plugin](https://github.com/Transmode/gradle-docker).

Example:
```
# ./gradlew buildDocker
```

This builds an image with tag name `<username>/kafka-mesos:<version>`.

Note: this will not push the image. Push should be done manually after testing.

# Running image
Running image using docker. Required networking params should be provided. Image has no entry point,
so ./kafka-mesos.sh should be specified explicitly.

Example:
```
# docker run -it -p 7000:7000 --add-host=master:192.168.3.5 <username>/kafka-mesos:<version> ./kafka-mesos.sh scheduler \
--master=master:5050 --zk=master:2181 --api=http://<accessible-ip>:7000 --storage=zk:/kafka-mesos
```

Note: if you want to inspect image content you can it without specifying `./kafka-mesos.sh` entry point.
In that case you will got shell access.

# Running image in Marathon
In order to run image in Marathon it is better to pre-pull image on the required (all) nodes using:
```
# sudo docker pull <image-name>
```

After that, scheduler process could be created via Marathon API via POST /v2/apps call.
Example:
```
{
    "container": {
        "type": "DOCKER",
        "docker": {
            "network": "HOST",
            "image": "$imageName"
        }
    },
    "id":"kafka-mesos-scheduler",
    "cpus": 0.5,
    "mem": 256,
    "cmd": "./kafka-mesos.sh scheduler --master=master:5050 --zk=master:2181 --api=http://master:7000 --storage=zk:/kafka-mesos",
    "instances": 1,
    "constraints": [["hostname", "LIKE", "master"]]
}
```

Then the cli should be able to connect to url http://master:7000 from your api client machine (typically different than the mesos slaves). Example:
```
# ./kafka-mesos.sh status --api=http://master:7000
Cluster status received

cluster:
  brokers:
```
Now you can configure and start brokers.