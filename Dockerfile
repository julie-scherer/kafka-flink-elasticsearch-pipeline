# These are the latest combinations of versions available on dockerhub and the Ubuntu
# PPAs as of 2023/05/06
FROM apache/flink:1.17.0-scala_2.12-java11
ARG FLINK_VERSION=1.17.0
ARG PYTHON_VERSION=3.10
ARG ICEBERG_VERSION=1.2.1
ARG ICEBERG_FLINK_RUNTIME_VERSION=1.14
# Install pre-reqs to add new PPA
RUN set -ex; \
    apt-get update && \
    # Install the pre-req to be able to add PPAs before installing python
    apt-get install -y software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add the python PPA for ubuntu/debian and install python
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    # Latest available python on the PPA for the underlying ubuntu jammy distro
    # is python 3.9 as of 2023/05/06
    apt-get install -y --no-install-recommends \
    wget \
    python${PYTHON_VERSION}-distutils \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-venv \
    python${PYTHON_VERSION} \
    libpython${PYTHON_VERSION}-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
    ln -s /usr/bin/python${PYTHON_VERSION} /usr/bin/python; \
    ln -s /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip

RUN python${PYTHON_VERSION} --version && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python${PYTHON_VERSION} ./get-pip.py ${PIP_VERSION}

RUN python${PYTHON_VERSION} -m pip install --upgrade pip; \
    pip install apache-flink==${FLINK_VERSION}; \
    pip install kafka-python;

# Download connector libraries
ARG FLINK_MAVEN_URL="https://repo.maven.apache.org/maven2/org/apache/flink"
RUN wget -P /opt/flink/lib/ ${FLINK_MAVEN_URL}/flink-json/${FLINK_VERSION}/flink-json-${FLINK_VERSION}.jar; \
    wget -P /opt/flink/lib/ ${FLINK_MAVEN_URL}/flink-sql-connector-kafka/${FLINK_VERSION}/flink-sql-connector-kafka-${FLINK_VERSION}.jar;

# Install iceberg and AWS dependencies
ARG ICEBERG_MAVEN_URL="https://repo1.maven.org/maven2/org/apache/iceberg"
RUN wget -P /opt/iceberg/lib $ICEBERG_MAVEN_URL/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}/$ICEBERG_VERSION/iceberg-flink-runtime-${ICEBERG_FLINK_RUNTIME_VERSION}-${ICEBERG_VERSION}.jar;

# Install AWS dependencies
ARG AWS_SDK_VERSION="2.20.18"
ARG AWS_MAVEN_URL="https://repo1.maven.org/maven2/software/amazon/awssdk"
RUN wget -P /opt/awssdk/lib/ ${AWS_MAVEN_URL}/bundle/${AWS_SDK_VERSION}/bundle-${AWS_SDK_VERSION}.jar;
RUN echo "taskmanager.memory.jvm-metaspace.size: 512m" >> /opt/flink/conf/flink-conf.yaml;
WORKDIR /opt/flink
