.PHONY: help dev build test proto lint clean install-deps

# Variables
PROTO_DIR := proto
SERVICES := user-service product-service order-service api-gateway
GO_FILES := $(shell find . -type f -name '*.go' | grep -v vendor)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install-deps: ## Install required dependencies
	@echo "Installing dependencies..."
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

proto: ## Generate protobuf code
	@echo "Generating protobuf code..."
	@for service in user product order; do \
		echo "Generating $$service proto..."; \
		protoc --go_out=. --go_opt=paths=source_relative \
			--go-grpc_out=. --go-grpc_opt=paths=source_relative \
			$(PROTO_DIR)/$$service/*.proto; \
	done

dev-infra: ## Start development infrastructure
	docker-compose -f docker-compose.dev.yml up -d postgres-user postgres-product postgres-order redis prometheus grafana jaeger
	@echo "Waiting for databases to be ready..."
	@sleep 10

dev-infra-down: ## Stop development infrastructure  
	docker-compose -f docker-compose.dev.yml down

build: ## Build all services
	@echo "Building services..."
	@for service in $(SERVICES); do \
		echo "Building $$service..."; \
		cd services/$$service && go build -o ../../bin/$$service ./cmd && cd ../..; \
	done

run-user: ## Run user service with hot reload
	cd services/user-service && air -c .air.toml

run-product: ## Run product service with hot reload
	cd services/product-service && air -c .air.toml

run-order: ## Run order service with hot reload
	cd services/order-service && air -c .air.toml

run-gateway: ## Run API gateway with hot reload
	cd services/api-gateway && air -c .air.toml

test: ## Run all tests
	@echo "Running tests..."
	go test -v -race ./...

test-coverage: ## Run tests with coverage
	go test -v -race -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

lint: ## Lint code
	golangci-lint run ./...

mod: ## Download and tidy dependencies
	go mod download
	go mod tidy

clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out coverage.html

init-db: ## Initialize database schemas
	@echo "Initializing databases..."
	@psql postgresql://userservice:userservice_dev_pass@localhost:5432/userdb -f scripts/init-user-db.sql
	@psql postgresql://productservice:productservice_dev_pass@localhost:5433/productdb -f scripts/init-product-db.sql
	@psql postgresql://orderservice:orderservice_dev_pass@localhost:5434/orderdb -f scripts/init-order-db.sql

dev: dev-infra proto mod ## Start full development environment
	@echo "Development environment is ready!"
	@echo "Run services in separate terminals:"
	@echo "  make run-user      # User service on :8080"
	@echo "  make run-product   # Product service on :8081"
	@echo "  make run-order     # Order service on :8082"
	@echo "  make run-gateway   # API Gateway on :8000"