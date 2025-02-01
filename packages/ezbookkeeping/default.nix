{ lib
, buildGoModule
, fetchFromGitHub
,
}:

buildGoModule rec {
  pname = "ezbookkeeping";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "mayswind";
    repo = "ezbookkeeping";
    rev = "v${version}";
    hash = "sha256-vj97QKPcAqNyS816KHMxIcwIizs4c6TRjMHTyqERu6A=";
  };

  vendorHash = "sha256-ENQggA9DaCn5o3KG5DoT1iK0NTOGQH4H0SkG4ClDFCQ=";

  CGO_ENABLED = 1;

  ldflags = [
    "-s"
    "-w"
    "-X main.Version=${version}"
    "-X main.CommitHash=${src.rev}"
    "-X main.BuildUnixTime=0000000000"
    "-linkmode external"
    "-extldflags '-static'"
  ];

  #buildPhase = ''
  #  go build -a -v -trimpath \
  #  -ldflags \
  #  "-w -s -linkmode external -extldflags '-static' -X 'main.Version=${version}' -X 'main.CommitHash=${src.rev}' -X 'main.BuildUnixTime=0000000000'" \
  #  -o ezbookkeeping ezbookkeeping.go
  #'';

  meta = {
    description = "A lightweight personal bookkeeping app hosted by yourself";
    homepage = "https://github.com/mayswind/ezbookkeeping";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "ezbookkeeping";
  };
}
