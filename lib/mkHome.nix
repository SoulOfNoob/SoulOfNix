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
  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;

  # Determine platform
  isDarwin = lib.hasSuffix "darwin" system;
  isLinux = lib.hasSuffix "linux" system;

  # Default username and home directory based on platform
  defaultUsername = if isDarwin then builtins.getEnv "USER" else "root";
  defaultHomeDir = if isDarwin
    then "/Users/${if username != null then username else defaultUsername}"
    else "/home/${if username != null then username else defaultUsername}";

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
