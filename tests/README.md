# SoulOfNix Tests

This directory contains Docker-based integration tests to verify that SoulOfNix installation works seamlessly across different Linux distributions.

## Philosophy

**Goal:** Prove that the **same script** runs seamlessly in **every environment**.

The tests follow the DRY (Don't Repeat Yourself) principle:
- ✅ **One test script** (`test-install.sh`) runs on all platforms
- ✅ **Minimal Dockerfiles** contain only platform-specific setup
- ✅ **Same profile** tested everywhere (remote profile by default)
- ✅ **Consistent verification** across all platforms

## Test Coverage

| Platform | Base Image | Init System | User Context | Profile |
|----------|------------|-------------|--------------|---------|
| Debian | `debian:bookworm-slim` | None (Docker) | testuser | remote |
| Alpine | `alpine:3.19` | None (Docker) | testuser | remote |
| Arch | `archlinux:latest` | None (Docker) | testuser | remote |
| Slackware/UnRAID | `debian:bookworm-slim` (simulated) | None (Docker) | root | remote |

## Quick Start

```bash
# Run all tests
make -C tests test

# Run individual platform tests
make -C tests test-debian
make -C tests test-alpine
make -C tests test-arch
make -C tests test-slackware

# Build images without running tests
make -C tests build

# Clean up test images
make -C tests clean
```

## Test Script

The single test script (`test-install.sh`) performs the following steps:

1. **Environment Detection**
   - Detects OS and architecture
   - Sets appropriate profile suffix (aarch64 vs x86_64)

2. **Nix Installation**
   - Installs Nix using Determinate Systems installer
   - Starts nix-daemon manually (Docker has no init system)
   - Sources Nix profile

3. **Flake Validation**
   - Runs `nix flake check --no-build`

4. **Home Manager Application**
   - Applies the remote profile with home-manager
   - Uses `--impure` flag for environment access

5. **Verification**
   - Checks that config files exist
   - Validates ZSH syntax
   - Runs platform-specific checks (e.g., UnRAID persistent history)

## Dockerfile Structure

Each Dockerfile contains **only** platform-specific setup:

### Common Pattern

```dockerfile
FROM <base-image>

# 1. Install dependencies (package manager specific)
RUN <package-manager> install bash curl git xz sudo

# 2. Create test user (platform specific)
RUN useradd -m -s /bin/bash testuser

# 3. Set platform-specific environment (if needed)
ENV LANG=C.UTF-8  # Alpine only

# 4. Copy files and test script
COPY --chown=testuser:testuser . /home/testuser/SoulOfNix/
COPY --chown=testuser:testuser tests/test-install.sh /home/testuser/test.sh

# 5. Run test
USER testuser
WORKDIR /home/testuser/SoulOfNix
CMD ["/home/testuser/test.sh"]
```

### Platform-Specific Differences

**Alpine:**
- Uses `apk add` instead of `apt-get`
- Requires `ENV LANG=C.UTF-8` for locale
- Includes `shadow` package for user management

**Arch:**
- Uses `pacman -S` for package installation
- Runs `pacman -Syu` to update system first

**Slackware/UnRAID:**
- Runs as root (typical for UnRAID)
- Simulates Slackware environment with `/etc/slackware-version`
- Creates `/boot/config/extra` for persistent storage simulation
- Tests UnRAID-specific history path configuration

## Customization

### Testing Different Profiles

Set the `TEST_PROFILE` environment variable:

```dockerfile
# In Dockerfile, before CMD
ENV TEST_PROFILE=local

# Or pass at runtime
docker run -e TEST_PROFILE=work soulofnix-test-debian
```

### Testing on Different Architectures

The test script automatically detects architecture:
- `x86_64` → tests `remote` profile
- `aarch64` → tests `remote-aarch64` profile

## Code Metrics

### Before Refactoring
- **Total lines:** ~260 lines across 4 Dockerfiles
- **Duplication:** 4 copies of nearly identical 65-line test scripts
- **Maintainability:** Change requires updating 4 files
- **Test consistency:** Different profiles tested on each platform

### After Refactoring
- **Total lines:** ~80 lines across 4 Dockerfiles + 1 shared script
- **Duplication:** 0 (single test script)
- **Maintainability:** Change requires updating 1 file
- **Test consistency:** Same profile tested everywhere

**Improvement:** 69% code reduction, 100% DRY compliance

## CI/CD Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run integration tests
  run: make -C tests test

# Or test individual platforms
- name: Test on Alpine
  run: make -C tests test-alpine
```

## Troubleshooting

### Test Failures

If tests fail:

1. **Check Nix installation:** Ensure Determinate Systems installer is accessible
2. **Check flake:** Run `nix flake check` manually
3. **Check architecture:** Verify correct profile suffix is used
4. **Check logs:** Docker logs show detailed error messages

### Local Development

To debug tests locally:

```bash
# Build and enter container interactively
docker build -t test-debug -f tests/docker/Dockerfile.debian .
docker run -it test-debug /bin/bash

# Then run test script manually
cd ~/SoulOfNix
./test.sh
```

## Architecture Decisions

### Why One Test Script?

**Problem:** Having test logic duplicated in each Dockerfile makes it hard to:
- Maintain consistency across platforms
- Update test logic (requires changing 4 files)
- Understand what's actually being tested
- Verify test script syntax before building

**Solution:** Extract test logic to a single script that all platforms use.

### Why Remote Profile?

The `remote` profile is used for testing because:
- ✅ **Minimal dependencies** → faster builds
- ✅ **Core functionality** → tests essential features
- ✅ **Universal** → works on all platforms (local/work have GUI tools)

### Why No Init System?

Docker containers don't run init systems by default, so:
- Nix daemon is started manually
- `--init none` flag is used for Nix installation
- Mirrors real-world Docker/container deployments

## Future Improvements

Potential enhancements:

- [ ] Add tests for Darwin (macOS) using Lima or Tart VMs
- [ ] Test all three profiles (remote, local, work) in sequence
- [ ] Add integration tests for specific tools (git, tmux, zsh)
- [ ] Add performance benchmarks (installation time, resource usage)
- [ ] Add tests for updating existing installations
- [ ] Add tests for rollback functionality

## Contributing

When adding new test scenarios:

1. **Add to test script** (`test-install.sh`) - not individual Dockerfiles
2. **Keep Dockerfiles minimal** - only platform-specific setup
3. **Document platform differences** - explain why differences exist
4. **Test on all platforms** - run `make test` before committing
