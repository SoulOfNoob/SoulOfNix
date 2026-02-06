# SSH configuration
{ config, lib, pkgs, authorizedKeys ? [ ], ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  programs.ssh = {
    enable = true;

    # Disable default config to avoid deprecation warning
    enableDefaultConfig = false;

    # Match blocks for configuration
    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          ControlMaster = "auto";
          ControlPath = "~/.ssh/sockets/%r@%h-%p";
          ControlPersist = "600";
          HashKnownHosts = "yes";
          VisualHostKey = "no";
        } // lib.optionalAttrs isDarwin {
          IdentityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
          AddKeysToAgent = "yes";
          UseKeychain = "yes";
        };
      };
    };

    # Known hosts file
    userKnownHostsFile = "~/.ssh/known_hosts";
  };

  # Create SSH sockets directory
  home.file.".ssh/sockets/.keep".text = "";

  # Manage authorized_keys for remote profile
  home.file.".ssh/authorized_keys" = lib.mkIf (authorizedKeys != [ ]) {
    text = lib.concatStringsSep "\n" authorizedKeys + "\n";
  };

  # SSH directory permissions are handled by home-manager activation
  # Note: Only chmod real files, not symlinks (which point to read-only nix store)
  home.activation.sshPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.ssh" ]; then
      $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
      # Only chmod if it's a real file, not a symlink
      [ -f "$HOME/.ssh/authorized_keys" ] && [ ! -L "$HOME/.ssh/authorized_keys" ] && $DRY_RUN_CMD chmod 600 "$HOME/.ssh/authorized_keys"
      [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ] && $DRY_RUN_CMD chmod 600 "$HOME/.ssh/config"
    fi
  '';
}
