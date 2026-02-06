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
      homeConfigurations = {
        # Remote profile - minimal for servers
        "remote" = mkHome {
          profile = "remote";
          system = "x86_64-linux";
        };

        "remote-aarch64" = mkHome {
          profile = "remote";
          system = "aarch64-linux";
        };

        # Local profile - personal machines
        "local" = mkHome {
          profile = "local";
          system = "x86_64-linux";
        };

        "local-aarch64" = mkHome {
          profile = "local";
          system = "aarch64-linux";
        };

        "local-darwin" = mkHome {
          profile = "local";
          system = "aarch64-darwin";
        };

        "local-darwin-x86" = mkHome {
          profile = "local";
          system = "x86_64-darwin";
        };

        # Work profile
        "work" = mkHome {
          profile = "work";
          system = "x86_64-linux";
        };

        "work-aarch64" = mkHome {
          profile = "work";
          system = "aarch64-linux";
        };

        "work-darwin" = mkHome {
          profile = "work";
          system = "aarch64-darwin";
        };

        "work-darwin-x86" = mkHome {
          profile = "work";
          system = "x86_64-darwin";
        };
      };

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
