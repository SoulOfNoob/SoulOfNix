# GitHub Actions Testing

## Quick Start

1. Push to GitHub
2. Go to **Actions** tab → **Tests**
3. Click **Run workflow**
4. Wait ~15 minutes

## What It Tests

**Linux (Docker):** Debian, Alpine, Arch, Slackware
**macOS (Native):** macOS 14 (Sonoma), macOS 15 (Sequoia) - Apple Silicon

Each platform:
- ✅ Installs Nix
- ✅ Applies home-manager config
- ✅ Verifies installation

## Enable Automatic Runs

Edit `.github/workflows/test.yml` line 4:

```yaml
# Change from:
on:
  workflow_dispatch:

# To:
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
```

## Cost

- **Linux:** Free (unlimited)
- **macOS:** 2,000 free minutes/month
- **Per run:** ~10 macOS minutes
- **~200 runs/month free**

## Troubleshooting

**macOS fails?** Check flake config exists for detected architecture
**Docker fails?** Check test logs: `make -C tests test-<platform>`
**Timeout?** Increase timeout or split workflows

---

For local testing: `make -C tests test`
