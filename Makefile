IMAGE_NAME ?= flink-eczachly-sreela-custom:latest

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

## Starts the Flink cluster, also builds the image if it has not been built yet
up: ./Dockerfile
	docker compose up --remove-orphans -d

## Starts the Flink cluster, also builds the image if it has not been built yet
down: ./Dockerfile
	docker compose -f docker-compose.yml -f docker-compose-kafka-generator.yml down
	docker rmi ${IMAGE_NAME}

## Builds the flink base image with pyFlink and the flink-sql kafka connector installed.
build: ./Dockerfile
	docker build --platform linux/amd64 -t ${IMAGE_NAME} .

## Starts the Flink cluster, builds the pyflink image if it has not been built yet, creates a demo kafka topic to ingest from
demo: ./Dockerfile
	docker compose -f docker-compose.yml -f docker-compose-kafka-generator.yml up --remove-orphans -d

## Removes unused artifacts from this setup
clean: ./Dockerfile
	docker rm eczachly-flink-*
	docker rmi ${IMAGE_NAME}
