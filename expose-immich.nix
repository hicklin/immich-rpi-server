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

    services.caddy = {
        enable = true;
        # This config requires connections from tailscale IPs to provide a proxy protocol header. 
        # This allows caddy to see the original IP of connection coming through the tailscale funnel.
        # This is required for IP banning to work.
        globalConfig = ''
            servers {
                listener_wrappers {
                    proxy_protocol {
                        allow 100.64.0.0/10
                        fallback_policy require
                    }
                    tls
                }
            }
        '';
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

    # Immich only listens on localhost
    services.immich.host = "127.0.0.1";
    
    # Firewall - only allow Tailscale
    networking.firewall = {
        enable = true;
        allowedUDPPorts = [ config.services.tailscale.port ];
        
        # Allow local network access to Caddy
        interfaces.end0.allowedTCPPorts = [ 8443 ];  # LAN interface
        # Use below if enabling PRIVATE ENDPOINT
        # interfaces.tailscale0.allowedTCPPorts = [ 8444 ];
        # interfaces.end0.allowedTCPPorts = [ 8444 8443 ];  # LAN interface
    };
    
    # Tailscale configuration
    services.tailscale.useRoutingFeatures = "server";
    
    # ensure the banlist file exists
    systemd.tmpfiles.rules = [
        "f /var/lib/caddy/banlist 0644 root root - -"
    ];

    # allow fail2ban to write to the caddy directory
    systemd.services.fail2ban.serviceConfig = {
        ReadWritePaths = [ "/var/lib/caddy" ];
    };
    
    # fail2ban action: Add banned IP to caddy ban list and reload caddy
    environment.etc."fail2ban/action.d/caddy-ban.conf".text = ''
        [Definition]
        actionban = echo "remote_ip <ip>" >> /var/lib/caddy/banlist && systemctl reload caddy
        # Read file -> remove IP -> save to TMP -> Overwrite original file -> Reload
        # We avoid 'sed -i' because it tries to create a temp file inside /var/lib/caddy
        actionunban = sed "/remote_ip <ip>/d" /var/lib/caddy/banlist > /tmp/banlist.tmp && cat /tmp/banlist.tmp > /var/lib/caddy/banlist && systemctl reload caddy
    '';

    # fail2ban filter: Unauthorised access (401) - Protects against password brute-force
    environment.etc."fail2ban/filter.d/unauthorised.conf".text = ''
        [Definition]
        failregex = ^.*"client_ip":"<HOST>".*"status":401.*$
        datepattern = "Date":\["%%a, %%d %%b %%Y %%H:%%M:%%S %%Z"\]
        ignoreregex =
    '';

    # fail2ban filter: Forbidden access (403) - Protects against API/URI scanning
    environment.etc."fail2ban/filter.d/forbidden.conf".text = ''
        [Definition]
        failregex = ^.*"client_ip":"<HOST>".*"status":403.*$
        datepattern = "Date":\["%%a, %%d %%b %%Y %%H:%%M:%%S %%Z"\]
        ignoreregex =
    '';

    # fail2ban filter: Not found (404) - Protects against API/URI scanning
    environment.etc."fail2ban/filter.d/not-found.conf".text = ''
        [Definition]
        failregex = ^.*"client_ip":"<HOST>".*"status":404.*$
        datepattern = "Date":\["%%a, %%d %%b %%Y %%H:%%M:%%S %%Z"\]
        ignoreregex =
    '';

    services.fail2ban = {
        enable = true;
        jails = {
            # Jail 1: Unauthorised access
            unauthorised.settings = {
                enabled = true;
                filter = "unauthorised";
                action = "caddy-ban";
                logpath = "/var/log/caddy/access-:8443.log";
                backend = "polling";
                maxretry = 20;
                findtime = 300;
                bantime = 43200;
            };            
            # Jail 2: Forbidden access
            forbidden.settings = {
                enabled = true;
                filter = "forbidden";
                action = "caddy-ban";
                logpath = "/var/log/caddy/access-:8443.log";
                backend = "polling";
                maxretry = 20;
                findtime = 300;
                bantime = 43200;
            };            
            # Jail 3: Not Found
            not-found.settings = {
                enabled = true;
                filter = "not-found";
                action = "caddy-ban";
                logpath = "/var/log/caddy/access-:8443.log";
                backend = "polling";
                maxretry = 20;
                findtime = 300;
                bantime = 43200;
            };            
        };
    };

}
