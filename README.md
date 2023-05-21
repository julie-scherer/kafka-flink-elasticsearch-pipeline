# Apache Flink Training
Week 5 Apache Flink Streaming Pipelines

### Pre-requisites

The following components will need to be installed:

1. docker [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
2. docker compose [https://docs.docker.com/compose/install/#installation-scenarios](https://docs.docker.com/compose/install/#installation-scenarios)

### Flink (with pyFlink)

1. Clone/fork the repo, navigate to the root directory.

2. Run the following commands:

```bash
make build # to create the base docker image
make up # to deploy docker compose
make job # to deploy payment_msg_processing job
```

Run the command below to show you what `make` commands are available and what they do:

```bash
make help
```

💡 If you are on an arm64 machine (e.g. Apple M1/M2), you will need to modify [line 40](https://github.com/EcZachly-Inc-Bootcamp/apache-flink-training/blob/f79ed9e0cb6b55d8ddfc55b234bceaad9e6189f0/Makefile#L40) in the Makefile to replace linux/amd64 -> linux/arm64
