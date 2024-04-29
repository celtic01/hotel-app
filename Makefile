# Variables
BINARY_NAME := web
BUILD_DIR := ./cmd/web

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

.PHONY: build run clean build-and-run
