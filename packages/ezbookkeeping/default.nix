{ lib, fetchFromGitHub, buildGoModule, buildNpmPackage, git }:
let
  version = "unstable-20250202";
  src = fetchFromGitHub {
    owner = "mayswind";
    repo = "ezbookkeeping";
    rev = "a5e7c483ef6de7bad51b47498953a6a553ded3e1";
    hash = "sha256-QhyhVr6dL1XV6mfcFDTA2/UtUi/EO3QOnzUbjBYGqjU=";
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

    npmDepsHash = "sha256-MxXAL+r3Kvh62Fpb3/8ud5GaG22SOOam+nDeIsDzkUo=";
    GITCOMMIT = src.rev;
    patches = [ ./git-rev-sync.patch ];

    installPhase = ''
      runHook preInstall

      cp -r ./dist $out

      runHook postInstall
    '';

    meta = _meta;
  };

  backend = buildGoModule rec {
    pname = "ezbookkeeping-backend";
    inherit src version;

    vendorHash = "sha256-3ynXWGpkej7AQZToDze7MT6FzpZjyaTREy8pbjCUzto";

    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${version}"
      "-X main.CommitHash=${src.rev}"
      "-X main.BuildUnixTime=0000000000"
    ];

    checkPhase = false;

    postInstall = ''
      cp -r ${src}/templates $out/bin/templates
    '';

    meta = _meta // {
      mainProgram = "ezbookkeeping";
    };
  };
}
