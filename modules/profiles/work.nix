# Work profile - work environment configuration
{ config, lib, pkgs, ... }:

{
  imports = [ ./local.nix ]; # Work extends local profile

  # Additional packages for work
  home.packages = [
    # Container tools
    pkgs.docker-compose

    # Cloud tools
    pkgs.awscli2

    # Database tools
    pkgs.mysql-client
    pkgs.postgresql

    # PHP development (if needed)
    # pkgs.php82
    # pkgs.php82Packages.composer
  ];

  # Work-specific ZSH configuration
  programs.zsh = {
    shellAliases = {
      # Docker aliases from ZSH-Environment/config/work/
      doco = "docker-compose";
      dcrm = ''docker-compose run --label "traefik.enable=false" --rm'';

      # Docker shortcuts
      dcup = "docker-compose up -d";
      dcdown = "docker-compose down";
      dclogs = "docker-compose logs -f";
      dcrestart = "docker-compose restart";
      dcps = "docker-compose ps";
      dcexec = "docker-compose exec";

      # AWS shortcuts
      awslocal = "aws --endpoint-url=http://localhost:4566";
    };

    initContent = lib.mkAfter ''
      # Profile indicator
      export SOUL_OF_NIX_PROFILE="work"

      # Work-specific environment variables
      # Add your work-specific env vars here or use direnv

      # Docker host (if using remote docker)
      # export DOCKER_HOST=tcp://localhost:2375
    '';
  };

  # Git configuration for work
  programs.git = {
    # Work email - override this in your local config
    # userEmail = "your.email@company.com";

    extraConfig = {
      # Sign commits if using GPG
      # commit.gpgsign = true;

      # Use different credentials for work repos
      # Can be overridden with includeIf in ~/.gitconfig
    };
  };
}
