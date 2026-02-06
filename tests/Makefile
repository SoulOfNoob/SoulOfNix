# SoulOfNix Test Makefile
# Run tests in Docker containers to validate installation on different platforms

DOCKER := docker
DOCKER_BUILD := $(DOCKER) build
DOCKER_RUN := $(DOCKER) run --rm

# Test images
IMAGES := alpine debian arch slackware

.PHONY: all build test clean help check fmt \
        build-alpine build-debian build-arch build-slackware \
        test-alpine test-debian test-arch test-slackware

all: test

# Build all test images
build: build-alpine build-debian build-arch build-slackware

build-alpine:
	@echo "Building test image: soulofnix-test-alpine"
	$(DOCKER_BUILD) -t soulofnix-test-alpine -f docker/Dockerfile.alpine ..

build-debian:
	@echo "Building test image: soulofnix-test-debian"
	$(DOCKER_BUILD) -t soulofnix-test-debian -f docker/Dockerfile.debian ..

build-arch:
	@echo "Building test image: soulofnix-test-arch"
	$(DOCKER_BUILD) -t soulofnix-test-arch -f docker/Dockerfile.arch ..

build-slackware:
	@echo "Building test image: soulofnix-test-slackware"
	$(DOCKER_BUILD) -t soulofnix-test-slackware -f docker/Dockerfile.slackware ..

# Run all tests
test: test-alpine test-debian test-arch test-slackware

# Individual tests
test-alpine: build-alpine
	@echo "Testing Alpine Linux..."
	$(DOCKER_RUN) soulofnix-test-alpine

test-debian: build-debian
	@echo "Testing Debian..."
	$(DOCKER_RUN) soulofnix-test-debian

test-arch: build-arch
	@echo "Testing Arch Linux..."
	$(DOCKER_RUN) soulofnix-test-arch

test-slackware: build-slackware
	@echo "Testing Slackware..."
	$(DOCKER_RUN) soulofnix-test-slackware

# Quick validation (just check flake)
check:
	@echo "Running nix flake check..."
	cd .. && nix flake check

# Format nix files
fmt:
	@echo "Formatting nix files..."
	cd .. && nix fmt

# Clean up test images
clean:
	@echo "Removing test images..."
	-$(DOCKER) rmi soulofnix-test-alpine soulofnix-test-debian soulofnix-test-arch soulofnix-test-slackware 2>/dev/null || true

# Help
help:
	@echo "SoulOfNix Test Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all          - Run all tests (default)"
	@echo "  build        - Build all test images"
	@echo "  test         - Run all tests"
	@echo "  test-alpine  - Test on Alpine Linux"
	@echo "  test-debian  - Test on Debian"
	@echo "  test-arch    - Test on Arch Linux"
	@echo "  test-slackware - Test on Slackware"
	@echo "  check        - Run nix flake check"
	@echo "  fmt          - Format nix files"
	@echo "  clean        - Remove test images"
	@echo "  help         - Show this help"
