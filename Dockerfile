###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

###############################################################################
# Build PyFlink Playground Image
###############################################################################

FROM --platform=linux/amd64 apache/flink:1.16.0-scala_2.12-java8
ARG FLINK_VERSION=1.16.0

# Install python3.7 and pyflink
# Pyflink does not yet function with python3.9, and this image is build on
# debian bullseye which ships with that version, so build python3.7 here.
RUN set -ex; \
  apt-get update && \
  apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libffi-dev lzma liblzma-dev && \
  wget https://www.python.org/ftp/python/3.7.9/Python-3.7.9.tgz && \
  tar -xvf Python-3.7.9.tgz && \
  cd Python-3.7.9 && \
  ./configure --without-tests --enable-shared && \
  make -j4 && \
  make install && \
  ldconfig /usr/local/lib && \
  cd .. && rm -f Python-3.7.9.tgz && rm -rf Python-3.7.9 && \
  ln -s /usr/local/bin/python3 /usr/local/bin/python && \
  ln -s /usr/local/bin/pip3 /usr/local/bin/pip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip; \
  pip install apache-flink==${FLINK_VERSION}; \
  pip install kafka-python;

# Download connector libraries
RUN wget -P /opt/flink/lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar; \
    wget -P /opt/flink/lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/${FLINK_VERSION}/flink-sql-connector-kafka-${FLINK_VERSION}.jar; \
    wget -P /opt/flink/lib/ https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-elasticsearch7/${FLINK_VERSION}/flink-sql-connector-elasticsearch7-${FLINK_VERSION}.jar;

# Install iceberg
ARG ICEBERG_MAVEN_URL="https://repo1.maven.org/maven2/org/apache/iceberg"
ARG ICEBERG_FLINK_RUNTIME_VERSION=1.16
ARG ICEBERG_VERSION=1.2.1
RUN wget -P /opt/iceberg/lib/ https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}/$ICEBERG_VERSION/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}-${ICEBERG_VERSION}.jar;

RUN echo "taskmanager.memory.jvm-metaspace.size: 512m" >> /opt/flink/conf/flink-conf.yaml;

WORKDIR /opt/flink
