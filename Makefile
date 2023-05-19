IMAGE_NAME ?= kafka-flink-iceberg:latest
CONTAINER_NAME ?= flink-julie
KAFKA_TOPIC ?= bootcamp-events

# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20

## Show help with `make help`
help:
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)



## Builds the flink base image with pyFlink and the flink-sql kafka connector installed.
# docker build --platform linux/amd64 -t ${IMAGE_NAME} .
build:
	docker-compose build 


## Starts the Flink cluster, also builds the image if it has not been built yet
up:
	docker compose up --remove-orphans -d


## Shuts down the Flink cluster, cleans dangling images
down: 
	docker compose down


## Checking Kafka service
kafka-logs:
	docker-compose exec kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic payment_msg


## Create a new Kafka topic
kafka-topic:
	docker-compose exec kafka kafka-topics.sh --bootstrap-server kafka:9092 --create --topic ${KAFKA_TOPIC} --partitions 8 --replication-factor 1


## Submit the PyFlink job
job:
	docker-compose exec jobmanager ./bin/flink run -py /opt/pyflink_jobs/payment_msg_processing.py -d


## Removes unused artifacts from this setup
clean:
	docker rm ${CONTAINER_NAME}
	docker rmi ${IMAGE_NAME}


# Source: https://github.com/apache/flink-playgrounds/tree/master/pyflink-walkthrough