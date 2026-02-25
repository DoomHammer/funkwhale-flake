{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.funkwhale.url = "../";
  outputs =
    {
      self,
      nixpkgs,
      funkwhale,
    }:
    {
      nixosConfigurations = {

        container = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          modules = [
            funkwhale.nixosModules.default
            (
              { pkgs, ... }:
              let
                hostname = "funkwhale";
                secretFile = pkgs.writeText "djangoSecret" "test123"; # DON'T DO THIS IN PRODUCTION - the password file will be world-readable in the Nix Store!
              in
              {
                boot.isContainer = true;

                # Let 'nixos-version --json' know about the Git revision
                # of this flake.
                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
                system.stateVersion = "23.05";

                # Network configuration.
                networking.useDHCP = false;
                networking.firewall.allowedTCPPorts = [ 80 ];
                networking.hostName = hostname;

                nixpkgs.overlays = [ funkwhale.overlays.default ];

                services.funkwhale = {
                  enable = true;
                  hostname = hostname;
                  defaultFromEmail = "noreply@funkwhale.rhumbs.fr";
                  protocol = "http"; # no ssl for virtualbox
                  forceSSL = false; # uncomment when LetsEncrypt needs to access "http:" in order to check domain
                  api = {
                    djangoSecretKeyFile = "${secretFile}";
                  };
                };

                # Overrides default 30M
                services.nginx.clientMaxBodySize = "100m";

                environment.systemPackages = with pkgs; [ neovim ];
              }
            )
          ];
        };

      };
    };
}
