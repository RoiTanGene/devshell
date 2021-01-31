{ lib, pkgs, config, ... }:
# Avoid breaking back-compat for now.
let
  # Because we want to be able to push pure JSON-like data into the
  # environment.
  strOrPackage = import ../nix/strOrPackage.nix { inherit lib pkgs; };

  # Transform the env vars into bash exports
  envToBash = env:
    builtins.concatStringsSep "\n"
      (lib.mapAttrsToList
        (k: v: "export ${k}=${lib.escapeShellArg (toString v)}")
        env
      );
in
with lib;
{
  options = {
    bash.extra = mkOption {
      internal = true;
      type = types.lines;
      default = "";
    };

    bash.interactive = mkOption {
      internal = true;
      type = types.lines;
      default = "";
    };

    env = mkOption {
      internal = true;
      type = types.attrs;
      default = { };
    };

    motd = mkOption {
      internal = true;
      type = types.nullOr types.str;
      default = null;
    };

    name = mkOption {
      internal = true;
      type = types.nullOr types.str;
      default = null;
    };

    packages = mkOption {
      internal = true;
      type = types.listOf strOrPackage;
      default = [ ];
    };
  };

  # Copy the values over to the devshell module
  config.devshell =
    {
      env_setup = envToBash config.env;
      packages = config.packages;
      startup.bash_extra = noDepEntry config.bash.extra;
      interactive.bash_interactive = noDepEntry config.bash.interactive;
    }
    // (lib.optionalAttrs (config.motd != null) { motd = config.motd; })
    // (lib.optionalAttrs (config.name != null) { name = config.name; })
  ;
}
