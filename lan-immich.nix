{ config, lib, ... }:
{
  options.lanImmich = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = {
    # use `host = "::";` for IPv6.
    services.immich.host = "0.0.0.0";

    networking = {
      firewall = {
      allowedTCPPorts = [ 2283 ];
      # required for Tailscale
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      };
    };
  };
}