{ config, pkgs, lib, ... }:

let
  gen-mtls-certs = pkgs.writeShellScriptBin "gen-mtls-certs" (builtins.readFile ./scripts/generate-mTLS-certs.sh);
in {
    assertions = [{
      assertion = !(config.lanImmich or false);
      message = ''
      Config lan-immich.nix and exposed-immich.nix are incompatible and cannot be imported together.
      Please import only one of:
          - ./lan-immich.nix
          - ./expose-immich.nix
      '';
    }];

    environment.systemPackages = with pkgs; [
        openssl
        nss
        jq
        gen-mtls-certs # Helper script to generate mTLS client certs
    ];

    environment.sessionVariables = {
        IMMICH_CERTS_DIR = "/var/lib/immich-certs";
    };

    services.caddy = {
        enable = true;
        logFormat = lib.mkForce "level DEBUG";
        virtualHosts = {
            # PUBLIC ENDPOINT (via Tailscale Funnel):
            # `tailscale funnel --bg --tcp 443 tcp://localhost:8443`
            # Full access to valid mTLS cert providers. Public access to photo share API.
            ":8443" = {
                extraConfig = builtins.readFile ./configs/immich-remote.Caddyfile;
            };

            # PRIVATE ENDPOINT (Tailscale VPN or LAN)
            # Full access for Tailscale and local IPs without TLS cert on pont 8444
            # For better security, only use this for testing. Add mTLS certs to all your trusted devices.
            # ":8444" = {
            #     extraConfig = builtins.readFile ./configs/immich-local.Caddyfile;
            # };
        };
    };

    users.users.caddy = {
        # Add caddy user to users group...
        extraGroups = [ "users" ];
    };

    # services.fail2ban = {
    #     enable = true;
    #     jails = {
    #         # Jail 1: Caddy endpoint blocking
    #         caddy-nocert.settings = {
    #             filter = caddy-nocert
    #             backend = systemd
    #             journalmatch = _SYSTEMD_UNIT=caddy.service
    #             maxretry = 5
    #             findtime = 300
    #             bantime = 86400
    #             action = iptables-allports[name=immich-403]
    #         };
            
    #         # Jail 2: Immich share password brute force
    #         immich-share-auth.settings = {
    #             filter = immich-share-auth
    #             backend = systemd
    #             journalmatch = _SYSTEMD_UNIT=immich-server.service
    #             maxretry = 5
    #             findtime = 300
    #             bantime = 86400
    #             action = iptables-allports[name=immich-share]
    #         };
    #     };
    # };

    # environment.etc."fail2ban/filter.d/immich-nocert.conf".text = ''
    #     [Definition]
    #     failregex = ^<HOST> - .* 403 .*$
    #     ignoreregex =
    # '';

    # # Todo regex
    # environment.etc."fail2ban/filter.d/immich-share-auth.conf".text = ''
    #     [Definition]
    #     failregex = ^.*Invalid.*password.*share.*<HOST>.*$
    #     ignoreregex =
    # '';

    # Immich only listens on localhost
    services.immich.host = "127.0.0.1";
    
    # Firewall - only allow Tailscale
    networking.firewall = {
        enable = true;
        allowedUDPPorts = [ config.services.tailscale.port ];
        
        # Allow local network access to Caddy
        interfaces.tailscale0.allowedTCPPorts = [ 8444 ];
        interfaces.end0.allowedTCPPorts = [ 8444 8443 ];  # LAN interface
    };
    
    # Tailscale configuration
    services.tailscale.useRoutingFeatures = "server";
    
}
