{ config, lib, pkgs, ... }:
let
  cfg = config.recipes.vaultwarden;
in
{
  meta.maintainers = with lib.maintainers; [ adtya ];
  options.recipes.vaultwarden = {
    enable = lib.mkEnableOption "vaultwarden";

    config = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.str;
        options = {
          WEB_VAULT_FOLDER = lib.mkOption {
            type = lib.types.str;
            default = "${cfg.webVaultPackage}/share/vaultwarden/vault";
            readOnly = true;
            description = "Web Vault folder. derived from webVaultPackage config option";
          };
          DATA_FOLDER = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/vaultwarden";
            readOnly = true;
            description = "Data directory used by vaultwarden. it cannot be changed as it's using systemd's StateDirectory";
          };
        };
      };
      description = "Vaultwarden is configured using environment variables";
      default = {
        ROCKET_ADDRESS = "::1"; # default to localhost
        ROCKET_PORT = 8222;
      };
      example = { DOMAIN = "https://example.com"; SIGNUPS_ALLOWED = false; };
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = null;
      example = [ "/etc/vaultwarden/env_file" ];
      description = "Files containing additional environment variables in the form KEY=VALUE";
    };

    package = lib.mkPackageOption pkgs "vaultwarden" { };

    databaseBackend = lib.mkOption {
      type = lib.types.enum [ "sqlite" "mysql" "postgresql" ];
      default = "sqlite";
      example = "postgresql";
      description = "The kind of database backend to use";
    };

    webVaultPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vaultwarden.webvault;
      defaultText = lib.literalExpression "pkgs.vaultwarden.webvault";
      description = "Web vault package to use.";
    };
  };

  config = lib.mkIf (cfg.enable == true) {
    systemd.services.vaultwarden = {
      description = "Vaultwarden Server";
      documentation = [ "https://github.com/dani-garcia/vaultwarden" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = cfg.config;
      serviceConfig = {
        Type = "notify";
        DynamicUser = true;
        EnvironmentFile = cfg.environmentFiles;
        AmbientCapabilities = [ "" ];
        CapabilityBoundingSet = [ "" ];
        DeviceAllow = [ "" ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        PrivateIPC = true;
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" "@resources" ] ++ [
          "~@clock"
          "~@debug"
          "~@module"
          "~@mount"
          "~@reboot"
          "~@swap"
          "~@cpu-emulation"
          "~@obsolete"
          "~@timer"
          "~@chown"
          "~@setuid"
          "~@privileged"
          "~@keyring"
          "~@ipc"
        ];
        SystemCallErrorNumber = "EPERM";
        StateDirectory = "vaultwarden";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "vaultwarden";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart = lib.getExe (cfg.package.override { dbBackend = cfg.databaseBackend; });
        Restart = "on-failure";
        RestartSec = 10;
        StartLimitBurst = 5;
      };
    };
  };
}

