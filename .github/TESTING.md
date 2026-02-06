# GitHub Actions Testing

## Status: ✅ Production Ready

**Automatic testing enabled** on all pushes to main and pull requests.

## Test Coverage

**12 tests run in parallel (~15 minutes total):**

### Linux (8 tests via Docker)
| Platform | Profiles | Status |
|----------|----------|--------|
| Debian | remote, local | ✅ |
| Alpine | remote, local | ✅ |
| Arch | remote, local | ✅ |
| Slackware | remote, local | ✅ |

### macOS (4 tests via GitHub runners)
| Version | Profiles | Status |
|---------|----------|--------|
| macOS 14 (Sonoma) | local, work | ✅ |
| macOS 15 (Sequoia) | local, work | ✅ |

## What Gets Tested

Each test verifies:
- ✅ Nix installation
- ✅ Flake evaluation
- ✅ Home-manager configuration applies
- ✅ ZSH, Tmux, Git configs created
- ✅ Syntax validation
- ✅ Platform-specific features

## Manual Testing

Can still trigger manually:
1. Go to **Actions** tab
2. Select **Tests** workflow
3. Click **Run workflow**

## Compatibility Fixes Applied

All home-manager v24.11+ compatibility issues resolved:
- ✅ `programs.git.extraConfig` → `programs.git.settings`
- ✅ `programs.git.aliases` → `programs.git.settings.alias`
- ✅ `programs.git.delta` → `programs.delta`
- ✅ `mysql-client` → `mariadb.client`
- ✅ SSH `userKnownHostsFile` updated
- ✅ Delta package conflict resolved

## Cost

- **Linux:** Free (unlimited)
- **macOS:** 2,000 free minutes/month
- **Per run:** ~10 macOS minutes
- **Usage:** ~200 runs/month possible

## Workflow File

`.github/workflows/test.yml` - 43 lines, simple and maintainable.

---

Last updated: 2026-02-06
Status: All tests passing ✅
