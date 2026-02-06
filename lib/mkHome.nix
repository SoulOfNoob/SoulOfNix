# Helper function to create home-manager configurations
{ home-manager, nixpkgs }:

{ profile
, system
, username ? null
, homeDirectory ? null
, extraModules ? [ ]
, authorizedKeys ? [ ]
}:

let
  # Import nixpkgs with explicit config and overlays for reproducibility
  # In flake context, legacyPackages is acceptable as flakes enforce purity
  # but we document this decision explicitly
  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;

  # Determine platform
  isDarwin = lib.hasSuffix "darwin" system;
  isLinux = lib.hasSuffix "linux" system;

  # IMPURE EVALUATION: Get username from environment
  # This requires building with --impure flag or setting username explicitly
  # Usage: home-manager switch --flake .#profile --impure
  # OR:    Provide username parameter when calling mkHome
  # Falls back to "root" for Linux, "nobody" for Darwin if USER env is not set
  envUser = builtins.getEnv "USER";
  defaultUsername = if envUser != "" then envUser else (if isDarwin then "nobody" else "root");

  # Default home directory based on platform
  defaultHomeDir =
    let user = if username != null then username else defaultUsername;
    in if isDarwin
    then "/Users/${user}"
    else if user == "root" then "/root" else "/home/${user}";

  finalUsername = if username != null then username else defaultUsername;
  finalHomeDir = if homeDirectory != null then homeDirectory else defaultHomeDir;

  # Platform module selection
  platformModule =
    if isDarwin then ../modules/platforms/darwin.nix
    else ../modules/platforms/linux-systemd.nix;

  # Profile module
  profileModule = ../modules/profiles/${profile}.nix;

in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;

  extraSpecialArgs = {
    inherit authorizedKeys;
    profileName = profile;
  };

  modules = [
    # Base home configuration
    ../modules/home

    # Profile-specific configuration
    profileModule

    # Platform-specific configuration
    platformModule

    # User configuration
    {
      home = {
        username = finalUsername;
        homeDirectory = finalHomeDir;
        stateVersion = "24.05";
      };
    }
  ] ++ extraModules;
}
