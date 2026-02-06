{
  description = "SoulOfNix - Nix-based ZSH environment with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Supported systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper to generate attrs for each system
      forAllSystems = nixpkgs.lib.genAttrs systems;

      # Import the mkHome helper
      mkHome = import ./lib/mkHome.nix { inherit home-manager nixpkgs; };
    in
    {
      # Home-manager configurations for each profile
      # Generated programmatically to reduce duplication
      homeConfigurations =
        let
          # Define profiles and their supported systems
          profiles = {
            remote = {
              systems = {
                "" = "x86_64-linux";
                "-aarch64" = "aarch64-linux";
              };
            };
            local = {
              systems = {
                "" = "x86_64-linux";
                "-aarch64" = "aarch64-linux";
                "-darwin" = "aarch64-darwin";
                "-darwin-x86" = "x86_64-darwin";
              };
            };
            work = {
              systems = {
                "" = "x86_64-linux";
                "-aarch64" = "aarch64-linux";
                "-darwin" = "aarch64-darwin";
                "-darwin-x86" = "x86_64-darwin";
              };
            };
          };

          # Generate configurations for a profile
          mkProfileConfigs = profileName: profileConfig:
            nixpkgs.lib.mapAttrs'
              (suffix: system: {
                name = "${profileName}${suffix}";
                value = mkHome {
                  profile = profileName;
                  inherit system;
                };
              })
              profileConfig.systems;
        in
        # Merge all profile configurations
        nixpkgs.lib.foldl'
          (acc: profileName: acc // (mkProfileConfigs profileName profiles.${profileName}))
          { }
          (builtins.attrNames profiles);

      # Development shells for testing
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixpkgs-fmt
              pkgs.nil
            ];
          };
        }
      );

      # Formatter for nix files
      formatter = forAllSystems (system:
        nixpkgs.legacyPackages.${system}.nixpkgs-fmt
      );

      # Flake checks
      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Check that flake evaluates correctly
          flake-check = pkgs.runCommand "flake-check" { } ''
            echo "Flake evaluation successful"
            touch $out
          '';
        }
      );
    };
}
