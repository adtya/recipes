{ lib, fetchFromGitHub, buildGoModule, buildNpmPackage, git }:
let
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "mayswind";
    repo = "ezbookkeeping";
    rev = "a26397131d629e214a493c75e64b88e08ad6704d";
    hash = "sha256-vj97QKPcAqNyS816KHMxIcwIizs4c6TRjMHTyqERu6A=";
  };
  _meta = {
    description = "A lightweight personal bookkeeping app hosted by yourself";
    homepage = "https://github.com/mayswind/ezbookkeeping";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ adtya ];
  };
in
{
  frontend = buildNpmPackage rec {
    pname = "ezbookkeeping-frontend";
    inherit src version;

    npmDepsHash = "sha256-f2cZ8XNhcK0Sh3qVNRMFcqRPalVNduCRPTSAtkL48/A=";
    GITCOMMIT = src.rev;
    patches = [ ./git-rev-sync.patch ];

    installPhase = ''
      cp -r ./dist $out
    '';
    meta = _meta;
  };
  backend = buildGoModule rec {
    pname = "ezbookkeeping-backend";
    inherit src version;

    vendorHash = "sha256-ENQggA9DaCn5o3KG5DoT1iK0NTOGQH4H0SkG4ClDFCQ=";

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
      "-X main.CommitHash=${src.rev}"
      "-X main.BuildUnixTime=0000000000"
    ];

    checkPhase = false;
    meta = _meta // {
      mainProgram = "ezbookkeeping";
    };
  };
}
