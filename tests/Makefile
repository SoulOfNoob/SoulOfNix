# SoulOfNix Test Makefile
# Run tests in Docker containers to validate installation on different platforms

DOCKER := docker
DOCKER_BUILD := $(DOCKER) build
DOCKER_RUN := $(DOCKER) run --rm

# Test images
IMAGES := alpine debian arch slackware

.PHONY: all build test clean help check fmt test-syntax test-lib rebuild-all \
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

# Test shell script syntax (fast, no Nix installation)
test-syntax:
	@echo "Checking shell script syntax..."
	@bash -n ../lib/install-common.sh && echo "✓ install-common.sh syntax valid"
	@bash -n ../install.sh && echo "✓ install.sh syntax valid"
	@bash -n ../install-headless.sh && echo "✓ install-headless.sh syntax valid"
	@bash -n test-install.sh && echo "✓ test-install.sh syntax valid"

# Test shared library functions (requires bash)
test-lib:
	@echo "Testing shared library functions..."
	@bash -c 'source ../lib/install-common.sh && \
	  echo "Testing detect_arch..." && arch=$$(detect_arch) && echo "  Detected: $$arch" && \
	  echo "Testing detect_os..." && os=$$(detect_os) && echo "  Detected: $$os" && \
	  echo "✓ All library function tests passed"'

# Rebuild all images without cache (useful for testing changes)
rebuild-all:
	@echo "Rebuilding all images without cache..."
	$(DOCKER_BUILD) --no-cache -t soulofnix-test-alpine -f docker/Dockerfile.alpine ..
	$(DOCKER_BUILD) --no-cache -t soulofnix-test-debian -f docker/Dockerfile.debian ..
	$(DOCKER_BUILD) --no-cache -t soulofnix-test-arch -f docker/Dockerfile.arch ..
	$(DOCKER_BUILD) --no-cache -t soulofnix-test-slackware -f docker/Dockerfile.slackware ..
	@echo "✓ All images rebuilt"

# Clean up test images
clean:
	@echo "Removing test images..."
	-$(DOCKER) rmi soulofnix-test-alpine soulofnix-test-debian soulofnix-test-arch soulofnix-test-slackware 2>/dev/null || true

# Help
help:
	@echo "SoulOfNix Test Makefile"
	@echo ""
	@echo "Main Targets:"
	@echo "  all            - Run all tests (default)"
	@echo "  build          - Build all test images"
	@echo "  test           - Run all tests"
	@echo "  clean          - Remove test images"
	@echo ""
	@echo "Individual Tests:"
	@echo "  test-alpine    - Test on Alpine Linux"
	@echo "  test-debian    - Test on Debian"
	@echo "  test-arch      - Test on Arch Linux"
	@echo "  test-slackware - Test on Slackware"
	@echo ""
	@echo "Development:"
	@echo "  check          - Run nix flake check"
	@echo "  fmt            - Format nix files"
	@echo "  test-syntax    - Check shell script syntax (fast)"
	@echo "  test-lib       - Test shared library functions"
	@echo "  rebuild-all    - Rebuild all images without cache"
	@echo ""
	@echo "Help:"
	@echo "  help           - Show this help"
