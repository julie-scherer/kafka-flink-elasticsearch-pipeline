# Apache Flink Training
Week 5 Apache Flink Streaming Pipelines

## Installation

[Installing minikube+helm+flink](https://www.notion.so/Installing-minikube-helm-flink-44828e96d2874ca39a96fc9f1d618364)

### Pre-requisites

The following components will need to be installed:

1. docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. docker compose [https://docs.docker.com/compose/install/#installation-scenarios](https://docs.docker.com/compose/install/#installation-scenarios)

### Flink (with pyFlink)

The Apache foundation provides container images and kubernetes operators for Flink out of the box, but these do not contain pyFlink support, they also do not include the jar files for certain connectors (e.g. the flink SQL kafka connector which we will be using). So we will build a custom image based on the public flink image. 

#### Step 1

Clone/fork the repo, navigate to the root directory.

#### Step 2

Run the following commands:

```bash
make build # to create the base docker image
make up # to deploy docker compose
make job # to deploy payment_msg_processing job
```

#### Step 3

```bash
make help
```

This should show you your options and what they do. As of this writing, they are:

```bash
Usage:
make <target>

Targets:
  help                 Show help with `make help`
  up                   Starts the Flink cluster, also builds the image if it has not been built yet
  down                 Shuts down the Flink cluster, cleans dangling images
  build                Builds the flink base image with pyFlink and the flink-sql kafka connector installed.
  demo                 Starts the Flink cluster, builds the pyflink image if it has not been built yet, creates a demo kafka topic to ingest from
  listen               Creates a kafka console consumer, i.e. prints the kafka messages to your console
  clean                Removes unused artifacts from this setup
```

💡 If you are on an arm64 machine (e.g. Apple M1/M2), you will need to modify [line 40](https://github.com/EcZachly-Inc-Bootcamp/apache-flink-training/blob/f79ed9e0cb6b55d8ddfc55b234bceaad9e6189f0/Makefile#L40) in the Makefile to replace linux/amd64 -> linux/arm64
