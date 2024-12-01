{ config, lib, pkgs, ... }:
let
  cfg = config.recipes.conduwuit;

  format = pkgs.formats.toml { };
  conduitSubmodule = { name, ... }: {
    options = {
      enable = lib.mkEnableOption "conduwuit";

      extraEnvironment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Extra Environment variables to pass to the conduwuit server.";
        default = { };
        example = { RUST_BACKTRACE = true; };
      };

      environmentFiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = null;
        example = [ "/etc/conduwit/env_file" ];
        description = "Files containing environment variables in the form KEY=VALUE";
      };

      package = lib.mkPackageOption pkgs "conduwuit" { };

      settings = lib.mkOption {
        type = lib.types.submodule {
          freeformType = format.type;
          options = {
            global = {
              server_name = lib.mkOption {
                type = lib.types.str;
                example = "example.com";
                description = "The server_name is the name of this server. It is used as a suffix for user # and room ids.";
              };
              address = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ "127.0.0.1" "::1" ];
                description = "Address(s) to listen on for connections by the reverse proxy/tls terminator.";
              };
              port = lib.mkOption {
                type = lib.types.port;
                default = 6167;
                description = "The port Conduit will be running on. You need to set up a reverse proxy in your web server (e.g. apache or nginx), so all requests to /_matrix on port 443 and 8448 will be forwarded to the Conduit instance running on this port";
              };
              database_path = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/conduwuit-${name}/";
                readOnly = true;
                description = ''
                  Path to the conduwuit database, the directory where conduwuit will save its data.
                  Note that due to using the DynamicUser feature of systemd, this value should not be changed
                  and is set to be read only.
                '';
              };
              database_backend = lib.mkOption {
                type = lib.types.enum [ "sqlite" "rocksdb" ];
                default = "rocksdb";
                example = "sqlite";
                description = ''
                  The database backend for the service. Switching it on an existing
                  instance will require manual migration of data.
                '';
              };
            };
          };
        };
        default = { };
        description = ''
          Generates the conduwuit.toml configuration file. Refer to
          <https://conduwuit.puppyirl.gay/configuration/examples.html#example-configuration>
          for details on supported values.
          Note that database_path can not be edited because the service's reliance on systemd StateDir.
        '';
      };
    };
  };

  systemdService = name: serviceDefinition:
    let configFile = format.generate "conduwuit-${name}.toml" serviceDefinition.settings; in {
      enable = serviceDefinition.enable;
      description = "Conduwuit Matrix Server (${name})";
      documentation = [ "https://conduwuit.puppyirl.gay" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      environment = serviceDefinition.extraEnvironment;
      serviceConfig = {
        Type = "notify";
        DynamicUser = true;
        EnvironmentFile = serviceDefinition.environmentFiles;
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
        StateDirectory = "conduwuit-${name}";
        StateDirectoryMode = "0700";
        RuntimeDirectory = "conduwuit-${name}";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        ExecStart = "${lib.getExe serviceDefinition.package} --config ${configFile}";
        Restart = "on-failure";
        RestartSec = 10;
        StartLimitBurst = 5;
      };
    };
  mkSystemdService = (name: serviceDefinition: lib.nameValuePair "conduwuit-${name}" (systemdService name serviceDefinition));
in
{
  meta.maintainers = with lib.maintainers; [ adtya ];
  options.recipes.conduwuit.instances = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule conduitSubmodule);
    default = { };
    defaultText = lib.literalExpression { };
    description = "Configuration for a conduwuit instance";
  };

  config = lib.mkIf (cfg.instances != { }) {
    systemd.services = lib.mapAttrs' mkSystemdService cfg.instances;
  };
}
