FROM mesosphere/mesos:0.22.1-1.0.ubuntu1404

ADD . /kafka

WORKDIR /kafka

RUN ./gradlew jav

RUN apt-get update && apt-get -y install wget

RUN wget -q https://archive.apache.org/dist/kafka/0.8.2.1/kafka_2.10-0.8.2.1.tgz

ENV MESOS_NATIVE_JAVA_LIBRARY /usr/local/lib/libmesos.so

ENTRYPOINT ["/kafka/kafka-mesos.sh", "scheduler"]
