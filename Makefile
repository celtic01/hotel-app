# Variables
BINARY_NAME := web
BUILD_DIR := ./cmd/web
POSTGRES_HOST := 127.0.0.1
POSTGRES_PORT := 5432
POSTGRES_USER := hotel_user
POSTGRES_DB := hotel_db

# Commands
build-and-run: build run

build:
	@echo "Building $(BINARY_NAME)..."
	@GOFLAGS="-test" go build -o $(BUILD_DIR)/$(BINARY_NAME) $(BUILD_DIR)

run:
	@echo "Running $(BINARY_NAME)..."
	@./$(BUILD_DIR)/$(BINARY_NAME)

clean:
	@echo "Cleaning up..."
	@rm -f $(BUILD_DIR)/$(BINARY_NAME)

start-db:
	@echo "Starting PostgreSQL container..."
	@docker-compose up -d db

stop-db:
	@echo "Stopping PostgreSQL container..."
	@docker-compose stop db

connect-db:
	@psql -h $(POSTGRES_HOST) -p $(POSTGRES_PORT) -U $(POSTGRES_USER) -d $(POSTGRES_DB)

.PHONY: build run clean build-and-run stop-db start-db
