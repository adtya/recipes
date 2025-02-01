{ config, lib, pkgs, ... }:
let
  cfg = config.recipes.ezbookkeeping;
  configFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.maintainers; [ adtya ];
  options.recipes.ezbookkeeping = {
    enable = lib.mkEnableOption "ezbookkeeping";
    package = lib.mkPackageOption pkgs [ "ezbookkeeping" "backend" ] { };

    frontendPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ezbookkeeping.frontend;
      defaultText = lib.literalExpression "pkgs.ezbookkeeping.frontend";
      description = "Package to use for frontend assets";
    };

    configuration = lib.mkOption {
      type = lib.types.submodule {
        freeformType = configFormat.type;
        options = {
          server.static_root_path = lib.mkOption {
            type = lib.types.str;
            default = "${cfg.frontendPackage}";
            readOnly = true;
            description = "Directory containing frontend assets.";
          };
          storage.local_filesystem_path = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/ezbookkeeping";
            readOnly = true;
            description = "Data directory used by ezBookkeeping. it cannot be changed as it's using systemd's StateDirectory";
          };

        };
      };
      default = { };
      description = "ezBookkeeping server configuration (https://ezbookkeeping.mayswind.net/configuration)";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = null;
      example = [ "/etc/ezbookkeeping/env_file" ];
      description = "Files containing additional environment variables in the form KEY=VALUE";
    };
  };

  config = lib.mkIf (cfg.enable == true) {
    systemd.services.ezbookkeeping = {
      description = "Ezbookkeeping Server";
      documentation = [ "https://ezbookkeeping.mayswind.net" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
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
        StateDirectory = "ezbookkeeping";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "ezbookkeeping";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart =
          let
            configFile = configFormat.generate "ezbookkeeping.ini" cfg.configuration;
          in
          "${lib.getExe cfg.package} --conf-path ${configFile} server run";
        Restart = "on-failure";
        RestartSec = 10;
        StartLimitBurst = 5;
      };
    };
  };
}
