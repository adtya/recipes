{ config, lib, pkgs, ... }:
let
  cfg = config.recipes.ezbookkeeping;
  format = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.maintainers; [ adtya ];
  options.recipes.ezbookkeeping = {
    enable = lib.mkEnableOption "ezbookkeeping";

    config = lib.mkOption {
      type = lib.types.submodule {
        freeformType = format.type;
        options = {
          global = {
            app_name = lib.mkOption {
              type = lib.types.str;
              default = "ezBookkeeping";
              description = "Application instance name, used in the two factor authentication";
            };
            mode = lib.mkOption {
              type = lib.types.enum [ "production" "development" ];
              default = "production";
              description = "Application run mode, affects web server debugging and logging";
            };
          };
          server = {
            protocol = lib.mkOption {
              type = lib.types.enum [ "http" "https" "socket" ];
              default = "http";
              description = "The protocol that web server provides";
            };
            http_addr = lib.mkOption {
              type = lib.types.str;
              default = "0.0.0.0";
              description = "The ip address to bind to for http or https protocol";
            };
            http_addr = lib.mkOption {
              type = lib.types.str;
              default = "8080";
              description = "The http port to bind to for http or https protocol";
            };
            domain = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = "The domain name used to access ezBookkeeping";
            };
            root_url = lib.mkOption {
              type = lib.types.str;
              default = "http://localhost:8080/";
              description = "The full url used to access ezBookkeeping in browser";
            };
            static_root_path = lib.mkOption {
              type = lib.types.str;
              default = "public";
              description = "Static file root path. The value can be relative or absolute path";
            };
          };
          database = {
            type = lib.mkOption {
              type = lib.types.enum [ "sqlite3" "mysql" "postgres" ];
              default = "sqlite";
              example = "postgres";
              description = "The kind of database backend to use";
            };
          };
        };
      };
      description = "ezBookkeeping server configuration (https://ezbookkeeping.mayswind.net/configuration)";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = null;
      example = [ "/etc/ezbookkeeping/env_file" ];
      description = "Files containing additional environment variables in the form KEY=VALUE";
    };

    package = lib.mkPackageOption pkgs "ezbookkeeping" { };
    frontendPackage = lib.mkOption {
      type = lib.types.package;
      default = pkgs.ezbookkeeping-frontend;
      defaultText = lib.literalExpression "pkgs.ezbookkeeping-frontend";
      description = "Front end package to use.";
    };
  };

  config = lib.mkIf (cfg.enable == true) let configFile = format.generate "ezbookkeeping.ini" cfg.config;
  in {
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
      ExecStart = "${lib.getExe cfg.package} --conf-path ${configFile}";
      Restart = "on-failure";
      RestartSec = 10;
      StartLimitBurst = 5;
    };
  };
}

