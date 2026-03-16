# Makefile for Assisted Intelligence

.PHONY: build start down test clean help logs

# Default target
help:
	@echo "Assisted Intelligence - Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build    Build agent docker image, flutter dependencies, and backend"
	@echo "  make start    Start background agent via docker-compose"
	@echo "  make down     Stop background agent"
	@echo "  make test     Run both Agent and Flutter tests"
	@echo "  make logs     Show the last 500 lines of the agent log"
	@echo "  make clean    Remove build artifacts and node_modules"

## Build all components
build:
	@echo "--- Installing & Building Backend (Firebase) ---"
	cd backend && npm install && npm run build
	@echo "--- Building Agent (Docker) ---"
	docker-compose build
	@echo "--- Fetching Flutter Dependencies ---"
	cd app && flutter pub get

## Start background services
start:
	@echo "--- Starting Headless Agent ---"
	docker-compose up -d
	@echo "--- Services are running ---"
	@echo "Use 'docker-compose logs -f' to see agent output."
	@echo "Start the UI manually with: cd app && flutter run"

## Stop background services
down:
	@echo "--- Stopping Headless Agent ---"
	docker-compose down

## Show logs
logs:
	@echo "--- Showing last 500 lines of agent.log ---"
	tail -n 500 logs/agent.log

## Run all tests
test:
	@echo "--- Running Agent Tests ---"
	cd agent && npm test
	@echo "--- Running Flutter Tests ---"
	cd app && flutter test

## Clean up
clean:
	@echo "--- Cleaning artifacts ---"
	rm -rf agent/node_modules
	rm -rf backend/node_modules
	rm -rf backend/lib
	cd app && flutter clean
