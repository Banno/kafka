#!/bin/sh

if [ ! -f ./kafka-mesos.sh ]
then
   cd /kafka
fi

jar='kafka-mesos*.jar'

check_jar() {
    jars=$(find . -maxdepth 1 -name "$jar" | wc -l)

    if [ $jars -eq 0 ]
    then
        echo "$jar not found"
        exit 1
    elif [ $jars -gt 1 ]
    then
        echo "More than one $jar found"
        exit 1
    fi
}

check_jar
java -jar $jar "$@"
