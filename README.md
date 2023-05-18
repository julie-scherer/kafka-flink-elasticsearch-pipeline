# eczachly-flink

## Installation

[Installing minikube+helm+flink](https://www.notion.so/Installing-minikube-helm-flink-44828e96d2874ca39a96fc9f1d618364)

### Pre-requisites

The following components will need to be installed:

1. docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. docker compose [https://docs.docker.com/compose/install/#installation-scenarios](https://docs.docker.com/compose/install/#installation-scenarios)
3. minikube [https://minikube.sigs.k8s.io/docs/start](https://minikube.sigs.k8s.io/docs/start)
4. helm

    ```bash
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    ```

### Flink (with pyFlink)

The Apache foundation provides container images and kubernetes operators for Flink out of the box, but these do not contain pyFlink support, they also do not include the jar files for certain connectors (e.g. the flink SQL kafka connector which we will be using). So we will build a custom image based on the public flink image. 

#### Step 1

Clone the below repo:

```bash
git clone https://github.com/sreeladas/flink-custom-image.git
cd flink-custom-image
```

#### Step 2

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
clean                Removes unused artifacts from this setup
```

💡 If you are on an arm64 machine (e.g. Apple M1/M2), you will need to modify [line 40](https://github.com/sreeladas/flink-custom-image/blob/141c013e84f25f6b76f8e296916174a4a7aba26b/Makefile#L40) in the Makefile to replace linux/amd64 -> linux/arm64

#### Step 3

We will use:
- `make build` to enable deploying to kubernetes (minikube)
- `make up` to deploy within docker compose
- `make demo` to test with a sample app