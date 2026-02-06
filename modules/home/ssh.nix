# SSH configuration
{ config, lib, pkgs, authorizedKeys ? [], ... }:

let
  inherit (pkgs.stdenv) isDarwin isLinux;
in
{
  programs.ssh = {
    enable = true;

    # Common SSH options
    extraConfig = ''
      # Prefer ed25519 keys
      IdentitiesOnly yes

      # Keep connections alive
      ServerAliveInterval 60
      ServerAliveCountMax 3

      # Reuse connections
      ControlMaster auto
      ControlPath ~/.ssh/sockets/%r@%h-%p
      ControlPersist 600

      # Security
      HashKnownHosts yes
      VisualHostKey no
    '' + lib.optionalString isDarwin ''
      # macOS: Use 1Password SSH agent
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

      # macOS: Use Keychain for passphrase
      AddKeysToAgent yes
      UseKeychain yes
    '';

    # Known hosts file
    userKnownHostsFile = "~/.ssh/known_hosts";
  };

  # Create SSH sockets directory
  home.file.".ssh/sockets/.keep".text = "";

  # Manage authorized_keys for remote profile
  home.file.".ssh/authorized_keys" = lib.mkIf (authorizedKeys != []) {
    text = lib.concatStringsSep "\n" authorizedKeys + "\n";
    # Proper permissions
  };

  # SSH directory permissions are handled by home-manager activation
  home.activation.sshPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ -d "$HOME/.ssh" ]; then
      $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
      [ -f "$HOME/.ssh/authorized_keys" ] && $DRY_RUN_CMD chmod 600 "$HOME/.ssh/authorized_keys"
      [ -f "$HOME/.ssh/config" ] && $DRY_RUN_CMD chmod 600 "$HOME/.ssh/config"
    fi
  '';
}
