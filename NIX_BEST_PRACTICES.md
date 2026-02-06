# Comprehensive Nix Best Practices and Anti-Patterns

Based on extensive research of nix.dev documentation and community resources.

---

## Table of Contents

1. [Nix Language Best Practices](#nix-language-best-practices)
2. [Flakes Best Practices](#flakes-best-practices)
3. [Module System Best Practices](#module-system-best-practices)
4. [Packaging and Derivations](#packaging-and-derivations)
5. [Cross-Platform Support](#cross-platform-support)
6. [Performance and Evaluation](#performance-and-evaluation)
7. [Security Considerations](#security-considerations)
8. [Binary Cache Configuration](#binary-cache-configuration)
9. [Development Environments](#development-environments)
10. [File Management](#file-management)
11. [Home Manager Integration](#home-manager-integration)
12. [Testing Best Practices](#testing-best-practices)
13. [Common Pitfalls and Troubleshooting](#common-pitfalls-and-troubleshooting)

---

## Nix Language Best Practices

### Always Quote URLs

**Anti-pattern:**
```nix
https://example.com
```

**Best practice:**
```nix
"https://example.com"
```

**Rationale:** RFC 45 deprecated unquoted URLs due to harmful side effects. Always quote URLs in Nix code.

### Avoid Recursive Attribute Sets

**Anti-pattern:**
```nix
rec {
  a = 1;
  b = a + 2;
}
```

**Best practice:**
```nix
let
  a = 1;
in {
  a = a;
  b = a + 2;
}
```

**Rationale:** Recursive sets can cause hard-to-debug "infinite recursion" errors when shadowing names (e.g., `rec { a = a; }`). Using `let ... in` bindings is safer and more explicit.

### Avoid Top-Level `with` Scopes

**Anti-pattern:**
```nix
with (import <nixpkgs> {});
# ... rest of code
```

**Best practice:**
```nix
let
  pkgs = import <nixpkgs> {};
  inherit (pkgs) curl jq;
in
# ... rest of code
```

**Rationale:**
- Static analysis tools cannot reason about code with `with` statements
- Multiple `with` statements create name ambiguity
- Scoping rules for `with` are not intuitive

### Don't Use Lookup Paths in Production

**Anti-pattern:**
```nix
<nixpkgs>
```

**Best practice:**
```nix
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz";
    sha256 = "SHA256_HASH";
  }) {};
in
# ... rest of code
```

**Rationale:** Lookup paths like `<nixpkgs>` depend on external `$NIX_PATH` environment variables, making results non-reproducible across machines. Pin Nixpkgs explicitly using fetchers.

### Always Set Config and Overlays Explicitly

**Anti-pattern:**
```nix
import <nixpkgs> {}
```

**Best practice:**
```nix
import <nixpkgs> {
  config = {};
  overlays = [];
}
```

**Rationale:** The top-level Nixpkgs expression reads impurely from the filesystem for configuration parameters. Explicitly setting these ensures reproducibility.

### Use Deep Merging for Nested Attributes

**Anti-pattern:**
```nix
{ a = { b = 1; }; } // { a = { c = 3; }; }
# Result: { a = { c = 3; }; }  -- b is lost!
```

**Best practice:**
```nix
pkgs.lib.recursiveUpdate
  { a = { b = 1; }; }
  { a = { c = 3; }; }
# Result: { a = { b = 1; c = 3; }; }
```

**Rationale:** The standard update operator (`//`) performs shallow merges only, removing nested keys unintentionally.

### Use Fixed Names for Source Paths

**Anti-pattern:**
```nix
src = ./.;
```

**Best practice:**
```nix
src = builtins.path {
  path = ./.;
  name = "my-project";
};
```

**Rationale:** Using relative paths makes builds depend on the parent directory name, causing needless rebuilds when directory names differ across environments.

### Additional Language Tips

**Attribute Set Design:**
- Use attribute paths for nested structures: `{ a.b.c = 1; }` is cleaner than manually nesting

**Function Patterns:**
- Leverage set patterns with default values: `{ x, y ? "foo", z ? "bar" }: ...`
- Remember that in `args@{ a ? 23, ... }`, `args` does not include default values

**Path Literals:**
- Path literals require at least one slash before interpolation: `./a.${foo}/b` is valid
- Absolute paths make expressions less portable - use strings when translating paths to config files

**Block Comments:**
- Cannot be nested - attempting `/* /* nested */ */` causes syntax errors
- Escape inner delimiters: `/* /* nested *\/ */`

---

## Flakes Best Practices

### Structure and Purpose

Flakes provide a standardized entry point (`flake.nix`) for sharing Nix code with:
- **inputs**: Dependencies declared with specific URLs (local or remote)
- **outputs**: A function producing packages, apps, shells, etc.
- **flake.lock**: Auto-generated file pinning all dependency versions

### Key Benefits

- **Discoverability**: Standardized structure that Nix validates automatically
- **Caching**: Reduces rebuild times in CI environments
- **Reproducibility**: Defaults to "pure mode," isolating builds from host system
- **Streamlined execution**: Native integration with v3 `nix` command

### Important Limitations

**Experimental Status**: Flakes are still experimental and subject to change.

**System Explicitness**: Must explicitly specify architecture (e.g., `x86_64-linux`) - no parameterization.

**Recursive Dependencies**: Without `follows` statements, different versions of the same dependency may be loaded.

**File Staging Requirement**: Git-tracked files must be staged (`git add`) for flakes to recognize them.

### Best Practices

**Use Follows for Dependency Management:**
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";  # Prevents duplicate nixpkgs
  };
};
```

**Keep Flakes as Lightweight Wrappers:**
Don't create monolithic flake-only implementations. Use flakes as thin wrappers around existing Nix code to preserve accessibility for non-flake users.

**Use flake-compat for Backwards Compatibility:**
Expose flake outputs to traditional Nix workflows using libraries like `flake-compat`.

**Git Add Files After Creation:**
For flakes in git repositories, only files in the working tree will be copied to the store. Remember to `git add` any project files after you first create them.

### Common Anti-Patterns

**Using flake-utils Without Understanding:**
Some believe flake-utils usage is an anti-pattern. Understand what abstractions you're using and why.

**Over-coupling with Flakes:**
Don't let the flake configuration system define how the internals of your build work. Separate configuration capability from actual definitions.

---

## Module System Best Practices

### Module Structure

A NixOS module is a file containing a Nix expression with a specific structure:
- Declares options for other modules to define
- Processes them and defines options declared in other modules
- Returns an attrset with `options` and `config` keys

### Option Declaration Best Practices

**Use mkEnableOption for Boolean Options:**
```nix
options.services.myservice.enable = lib.mkEnableOption "My Service";
```
This creates a boolean option with a descriptive explanation, defaulting to false.

**Choose Appropriate Option Types:**
- Use submodules for nested configurations
- Basic types include multiple string types that differ in how merging is handled
- Submodules define sub-options handled like separate modules

**Document Your Options:**
Always provide clear descriptions for options. The NixOS module system generates documentation from these.

### Conditional Configuration

**Use lib.mkIf for Conditional Logic:**
```nix
config = lib.mkIf cfg.enable {
  # configuration here
};
```

### Priority and Merging

**Understanding Priority Functions:**
- `lib.mkDefault`: Sets a default value (can be overridden)
- `lib.mkForce`: Forces a value (overrides defaults and normal assignments)
- `lib.mkBefore`: Sets merge order for list-type options (prepends)
- `lib.mkAfter`: Sets merge order for list-type options (appends)

### Module Organization

**Start Small:**
If you're not very familiar with Nix, start with a small and simple configuration and gradually make it more elaborate as you learn.

**Modularize Configuration:**
Separate concerns into different modules. Don't create monolithic configuration files.

**Use lib Functions:**
Using `lib` simplifies handling options and helps follow best practices.

---

## Packaging and Derivations

### Common mkDerivation Pitfalls

**1. Silent Typos in Argument Names**
`mkDerivation` doesn't validate argument names and silently ignores typos. Double-check attribute names.

**2. Missing Required Dependencies**
The build environment is isolated from the system. All dependencies must be explicitly declared in `buildInputs`, `nativeBuildInputs`, or similar attributes.

**3. Forgetting Pre/Post Hooks in Phase Overrides**

**Anti-pattern:**
```nix
installPhase = ''
  mkdir -p $out/bin
  cp myapp $out/bin/
'';
```

**Best practice:**
```nix
installPhase = ''
  runHook preInstall

  mkdir -p $out/bin
  cp myapp $out/bin/

  runHook postInstall
'';
```

**Rationale:** Even if you don't use hooks directly, include them for downstream users who may want to add hooks by overriding your derivation.

**4. Incorrect Version Overrides**
When changing package versions, override both `version` and `src` attributes:
```nix
package.override {
  version = "2.0.0";
  src = fetchurl { ... };
}
```

**5. Infinite Recursion with overrideAttrs**
In `.overrideAttrs(finalAttrs: previousAttrs: e)`, only attribute *values* in expression `e` can depend on `finalAttrs`. Attribute *names* depending on `finalAttrs` cause infinite recursion.

**6. Use Language-Specific Builders**
- Use `mkDerivation` only for C/C++ projects
- Use trivial builders for simple files
- Use language-specific builders (e.g., `buildPythonPackage`) for everything else

---

## Cross-Platform Support

### Darwin/macOS Limitations

**Key Constraint:** It's only possible to cross-compile between `aarch64-darwin` and `x86_64-darwin`. Cross-compiling from/to Linux is not supported due to macOS being partially closed-source.

**Recent Status:** aarch64-darwin support was recently added, so cross-compilation is barely tested.

### Cross-Compilation Best Practices

**Use pkgsCross for Predefined Platforms:**
```nix
pkgs.pkgsCross.aarch64-multiplatform.hello
```

Nixpkgs provides predefined host platforms via `pkgsCross`, eliminating manual platform configuration.

**Binary Cache Considerations:**
Cross-compiled binaries are NOT cached on the official binary cache. Set up custom binary caches with CI/CD to avoid excessive recompilation.

**Platform Specification:**
When constructing platform configs manually, use the template: `<cpu>-<vendor>-<os>-<abi>`

**Officially Cached Systems (as of 2026):**
- aarch64-linux
- aarch64-darwin
- i686-linux
- x86_64-linux
- x86_64-darwin

### Multi-Platform Flake Structure

**Pattern for Shared Configuration:**
```nix
{
  outputs = { self, nixpkgs }: {
    # Shared packages
    packages = nixpkgs.lib.genAttrs
      [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ]
      (system: {
        default = ...;
      });
  };
}
```

Structure configurations with shared elements across platforms, separating system-specific configurations while sharing common packages and tools.

---

## Performance and Evaluation

### Lazy Evaluation Fundamentals

**How It Works:**
Nix uses thunks (unevaluated expressions) to implement laziness. Expressions are not evaluated until their values are needed.

**Benefits:**
- Avoids unnecessary computations
- Unused expressions never evaluate, removing need for many control flow constructs
- Can improve performance when used properly

### Performance Pitfalls

**Too Many Thunks:**
It's very easy to introduce excessive thunks in Nix code. Consequences:
- Thunks prevent garbage collection of referenced variables
- Keeps thunk memory AND all references alive
- Deeply nested thunk chains can lead to stack overflows

**Memory Pressure:**
Memory usage can balloon if large unevaluated thunks pile up, leading to unexpected memory pressure.

### Recent Performance Improvements (2025-2026)

**Lazy Trees:**
Available in Determinate Nix 3.6.7+, offers:
- 3x faster evaluation in many standard flake scenarios
- 20x+ reduction in disk usage in some cases
- Especially beneficial for monorepos

**Parallel Evaluation:**
Multi-threaded evaluation can provide 3-4x speedups:
- Example: 23.70s → 5.77s on 12-core processor (4.1x speedup)

### Import From Derivation (IFD) - Use Sparingly

**Performance Issues:**
- Evaluation can only finish when all required store objects are realized
- Sequential evaluator finds store paths one at a time
- Switches back and forth between evaluation and realization phases
- Makes builds really slow when many projects use IFD simultaneously

**Additional Concerns:**
- Potential for non-determinism
- Increased complexity in cross-platform builds
- Overhead and complexity should be carefully weighed

**When to Avoid IFD:**
Most cases. Only use when the dynamic capabilities are absolutely necessary.

### Evaluation Best Practices

**Minimize Evaluation Scope:**
Don't evaluate more than necessary. Leverage lazy evaluation to your advantage.

**Profile When Needed:**
Use evaluation profiling tools to identify bottlenecks in complex configurations.

**Cache Aggressively:**
Flakes cache builds to reduce rebuild times. Leverage this in CI/CD pipelines.

---

## Security Considerations

### Build Sandboxing

**What It Does:**
Whenever Nix builds anything, it sandboxes that process from everything else on the host system. Builds see only:
- Dependencies in the Nix store
- Temporary build directory
- Private versions of /proc, /dev, /dev/shm, /dev/pts (on Linux)
- Paths configured with `sandbox-paths`

**Benefits:**
- Ensures reproducibility
- Isolates builds from host system state
- Prevents builds from affecting each other

### Restricted Evaluation

**Purpose:** Ensures evaluation doesn't require any builds, regardless of store state.

**Configuration:**
```nix
{
  nix.settings.allow-import-from-derivation = false;
}
```

Throws an error when evaluation uses IFD, even if the required store object is available.

**Pure Evaluation Mode:**
Ensures Nix expression results are fully determined by explicitly declared inputs, not influenced by external state. Restricts filesystem and network access to files specified by cryptographic hash.

### Privilege Dropping

Following the principle of least privilege, Nix attempts to drop supplementary groups when building with sandboxing.

### Runtime Application Sandboxing

For runtime sandboxing of applications (not just builds), consider **NixPak**:
- Declarative wrapper around bwrap
- Can sandbox all sorts of Nix-packaged applications, including graphical ones

### Binary Cache Security

See [Binary Cache Configuration](#binary-cache-configuration) section below.

---

## Binary Cache Configuration

### Server-Side Security (Setting Up a Cache)

**Cryptographic Signing:**
Generate key pairs to ensure cache authenticity:
```bash
nix-store --generate-binary-cache-key \
  cache.example.com \
  cache-private-key.pem \
  cache-public-key.pem
```

**Private Key Protection:**
- Store private keys securely at `/var/secrets/cache-private-key.pem`
- Set permissions: `chmod 600 cache-private-key.pem`
- Only nix-serve should access the private key

**HTTPS Configuration:**
Enable HTTPS with SSL/TLS to prevent man-in-the-middle attacks:
```nix
{
  services.nginx = {
    virtualHosts."cache.example.com" = {
      enableACME = true;
      forceSSL = true;
    };
  };
  security.acme.email = "admin@example.com";
}
```

**Proxy Architecture:**
Since nix-serve doesn't support IPv6 or SSL/HTTPS natively, use nginx as a reverse proxy.

**Storage Optimization:**
- Configure `nix.gc` options for automatic garbage collection
- Configure `nix.optimise` options for periodic Nix store optimization

**Authentication for Private Caches:**
Use auth tokens to protect read access to private binary caches.

### Client-Side Configuration (Using a Cache)

**Persistent Configuration (/etc/nix/nix.conf):**
```
substituters = https://cache.nixos.org https://cache.example.com
trusted-public-keys = cache.nixos.org-1:... cache.example.com:...
```

**NixOS Declarative Configuration:**
```nix
{
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://cache.example.com"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:..."
      "cache.example.com:..."
    ];
  };
}
```

**Use extra- Prefix to Supplement Defaults:**
```nix
{
  nix.settings = {
    extra-substituters = [ "https://cache.example.com" ];
    extra-trusted-public-keys = [ "cache.example.com:..." ];
  };
}
```

**Security Best Practice:**
NEVER add a cache without its corresponding public key. Doing so allows unsigned packages to bypass verification.

### Verification Steps

1. Query cache availability:
   ```bash
   curl http://cache.example.com/nix-cache-info
   ```

2. Inspect store object signatures to confirm "Sig:" headers match your public key

3. Deploy incrementally using `nixos-rebuild switch`

### Alternatives

For reduced operational overhead, consider:
- S3-compatible backends (Tigris, Cloudflare R2)
- Managed services like Cachix

---

## Development Environments

### Declarative Shell Environments (shell.nix)

**Core Principles:**

**Declare, Don't Repeat:**
Rather than typing `nix-shell -p cowsay lolcat` repeatedly, create a `shell.nix` file:
```nix
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz";
    sha256 = "SHA256_HASH";
  }) {
    config = {};
    overlays = [];
  };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    cowsay
    lolcat
  ];
}
```

**Pin Nixpkgs to Specific Revisions:**
Always fetch a specific tarball to prevent unexpected dependency changes.

**Use mkShellNoCC for Non-Build Environments:**
The lightweight approach is appropriate for general development that doesn't require build tools.

**Explicit Configuration Settings:**
Always set `config = {}` and `overlays = []` explicitly to avoid inadvertent overrides by global configuration.

### Environment Customization

**Three Mechanisms:**

1. **Packages** - List tools needed in your environment
2. **Environment Variables** - Any attribute with a string-coercible value becomes an environment variable
3. **Shell Hooks** - Use `shellHook` for startup commands:
   ```nix
   mkShellNoCC {
     packages = [ ... ];
     shellHook = ''
       echo "Welcome to the development environment!"
     '';
   }
   ```

**Important:** Some environment variables (like `PS1`) are protected. Use `shellHook` to override them.

### Reproducible Scripts

**Shebang Pattern:**
```bash
#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p bash cacert curl jq python3Packages.xmljson
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/COMMIT_HASH.tar.gz
```

**Key Elements:**
- `-i bash`: Specifies interpreter
- `--pure`: Excludes most environment variables, preventing unintended system dependencies
- `-p`: Lists all required packages explicitly
- `-I`: Pins Nixpkgs to specific commit
- Include `cacert` when scripts require SSL authentication

### Ad-hoc vs Declarative Environments

**Use Ad-hoc For:**
- Immediate experimentation
- One-time program execution (`nix-shell --run`)
- Temporarily adding tools to current environment

**Use Declarative For:**
- Reproducibility requirements
- Development workflows
- Team collaboration
- Production or sharing

**Key Insight:** Ad-hoc prioritizes convenience; declarative prioritizes reproducibility.

### direnv Integration

Automate environment activation with direnv for seamless development workflows.

---

## File Management

### The lib.fileset Approach

**Core Principle:**
Avoid implicit path coercion. The pattern `src = ./.;` copies entire directories to the Nix store, including unneeded files, causing unnecessary rebuilds.

**Use lib.fileset for Explicit Control:**
File sets are never added to the Nix store unless explicitly requested, providing security against accidental secret exposure.

### Key Anti-Patterns

**1. Directory Rebuilding Loops**
When `src` references the whole directory and Nix creates a `result` symlink, Nix will rebuild every time contents change. Use `difference` to exclude the symlink:
```nix
src = lib.fileset.difference ./. ./result;
```

**2. Missing Path Errors**
Attempting to subtract a non-existent path causes failures. Wrap uncertain paths:
```nix
src = lib.fileset.maybeMissing ./optional-path;
```

**3. Overly Broad Filtering**
Including all files by default means new unintended files get copied.

### Recommended Patterns

**Exclude-Based Filtering (for evolving projects):**
```nix
src = lib.fileset.toSource {
  root = ./.;
  fileset = lib.fileset.difference ./. (lib.fileset.unions [
    ./result
    ./.git
    ./build
  ]);
};
```
New files are automatically included.

**Include-Based Filtering (for stable projects):**
```nix
src = lib.fileset.toSource {
  root = ./.;
  fileset = lib.fileset.unions [
    ./src
    ./tests
    ./package.json
  ];
};
```
New additions are ignored by default - more predictable and maintainable.

**Git-Aware Filtering:**
```nix
src = lib.fileset.toSource {
  root = ./.;
  fileset = lib.fileset.intersection
    (lib.fileset.gitTracked ./.)
    ./src;
};
```
Respects `.gitignore` semantics while enabling additional filtering.

### Performance Considerations

**Lazy Evaluation:**
File set evaluation is lazy - tracing files doesn't copy them. Only `toSource` triggers actual store operations.

**Efficient Filtering:**
Use `fileFilter` with predicates:
```nix
lib.fileset.fileFilter (file: file.hasExt "nix") ./.
```
Maintainable and scalable without manual enumeration.

---

## Home Manager Integration

### Integration Methods

Home Manager can be used:
1. **Standalone** - Recommended for non-NixOS/Darwin platforms
2. **NixOS Module** - Integrated into NixOS system configuration
3. **nix-darwin Module** - Integrated into nix-darwin system configuration

### Best Practices

**Keep Nixpkgs Versions Consistent:**
When using flakes with NixOS, ensure home-manager's `inputs.nixpkgs` follows the main flake's nixpkgs:
```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

**Start Small:**
If not very familiar with Nix, start with a small and simple configuration and gradually make it more elaborate as you learn.

**Modular Organization:**
Basic structure:
- Custom packages under `pkgs`
- Overlays
- Custom NixOS and home-manager modules

**Declarative Configuration:**
Home Manager has options to configure many common tools, allowing declarative generation of configuration files (Git, Neovim, etc.).

### Development Environment Patterns

Home Manager provides practical patterns for cohesive development workflows:
- Git configuration
- Text editor setup (Neovim, etc.)
- Shell configuration
- Tool-specific settings

---

## Testing Best Practices

### NixOS Integration Testing

**Core Testing Pattern:**
Uses `testers.runNixOSTest` with three essential components:
```nix
{
  name = "my-test";

  nodes = {
    machine1 = { ... };
    machine2 = { ... };
  };

  testScript = ''
    # Python code here
  '';
}
```

### VM Configuration Best Practices

**Pin Nixpkgs:**
Always pin to a specific version for reproducibility.

**Explicit Configuration:**
Explicitly set configuration options and overlays to avoid inadvertent overrides.

**Essential Settings:**
- Include `system.stateVersion` in configurations
- Configure only necessary services
- Set firewall rules explicitly

### Testing Patterns

**Single Machine Tests:**
```python
machine.succeed("systemctl is-active myservice")
machine.fail("curl http://localhost:8080")  # Should fail
```

**Multi-Machine Scenarios:**
```python
start_all()
machine1.wait_for_unit("default.target")
machine2.wait_for_unit("default.target")

machine1.succeed("curl http://machine2:80")
```

### Interactive Development

**Debug with driverInteractive:**
```bash
nix-build -A driverInteractive
./result/bin/nixos-test-driver
```

Enables:
- Manual Python REPL access to machines
- Interactive shell sessions within VMs
- Test script validation before automation

### Caching Consideration

Test results are kept in the Nix store and cached when unchanged. Manually clean to re-run successful tests - efficient for CI pipelines.

---

## Common Pitfalls and Troubleshooting

### Pinning and Reproducibility

**Problem:** Using unpinned `<nixpkgs>` for production
**Solution:** Always pin Nixpkgs to specific commits for reproducibility across machines and time

**Version Selection:**
- **Stable releases**: Follow specific NixOS version (e.g., `nixos-24.05`) for predictability
- **Unstable channel**: Use `nixos-unstable` for latest packages, accepting more frequent changes
- Use [status.nixos.org](https://status.nixos.org/) to identify tested commits

### Overlays Pitfalls

**Problem:** Global overlays affecting too much
**Solution:** Scope overlays appropriately

**Understanding final and prev:**
- `final`: nixpkgs WITH your overlay applied
- `prev`: nixpkgs WITHOUT your overlay applied

**Downside of Global Overlays:**
- Increased local compilation due to cache invalidation
- Potential functionality issues with affected packages

**Solution for Scoped Overlays:**
Instantiate a new nixpkgs instance:
```nix
let
  customPkgs = import nixpkgs {
    overlays = [ myOverlay ];
  };
in
# Use customPkgs instead of global pkgs
```

### Docker Image Best Practices

**Use dockerTools.buildImage:**
Nix replaces Dockerfile functionality. Don't try to replicate Dockerfile patterns.

**Platform-Specific Handling:**
For non-Linux systems:
- Set up remote Linux build machines, or
- Cross-compile to Linux targets

**Reproducible Image Tags:**
Generated image tag (from Nix build hash) ensures Docker image corresponds to Nix build.

**Combined Build and Load:**
```bash
docker load < $(nix-build hello-docker.nix)
```
Nix rebuilds if there are changes and passes new store path to docker load.

### Common Evaluation Errors

**Infinite Recursion:**
- Check for `rec` usage with shadowed names
- Verify `overrideAttrs` doesn't have attribute names depending on `finalAttrs`

**Stack Overflow:**
- Too deeply nested thunk chains
- Reduce thunk depth in lazy evaluation chains

**Missing Dependencies:**
- Explicitly declare all dependencies
- Remember the build environment is isolated

### Non-NixOS Binary Execution

**Problem:** Running non-Nix executables on NixOS
**Solutions:**
1. Use packaged versions from Nixpkgs
2. Build from source using `autoPatchelfHook`
3. Use `buildFHSEnv` for FHS-like environments
4. Enable `nix-ld` to create a library path
5. Use `steam-run` as a fallback

---

## Additional Resources

### Official Documentation
- [nix.dev](https://nix.dev/) - Official Nix documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Nix Reference Manual](https://nix.dev/manual/nix/stable/)

### Community Resources
- [NixOS Wiki](https://wiki.nixos.org/)
- [NixOS Discourse](https://discourse.nixos.org/)
- [Zero to Nix](https://zero-to-nix.com/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)

### Tools
- **nixfmt** - Official Nix code formatter
- **nix-tree** - Interactively browse dependency graphs
- **nix-diff** - Explain why two Nix derivations differ
- **npins** - Automated dependency pinning
- **Cachix** - Binary cache hosting

---

## Summary of Key Principles

1. **Reproducibility First**: Always pin dependencies, avoid lookup paths, set explicit configurations
2. **Explicit Over Implicit**: Declare dependencies, avoid `with`, use explicit imports
3. **Modular Design**: Break configurations into manageable modules
4. **Security Conscious**: Use sandboxing, verify binary cache signatures, restrict evaluation when needed
5. **Performance Aware**: Minimize IFD, leverage lazy evaluation, use binary caches
6. **Cross-Platform Considerate**: Test on target platforms, understand cross-compilation limitations
7. **Documentation**: Comment complex expressions, use descriptive option descriptions
8. **Start Simple**: Begin with minimal configurations and expand gradually

---

*This document is based on research conducted in February 2026 from nix.dev documentation and community resources.*
