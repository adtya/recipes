{ lib
, buildGoModule
, fetchFromGitHub
, callPackage
, nodejs
, pnpm
}:
let
  inherit (import ./sources.nix { inherit fetchFromGitHub; }) pname version src vendorHash;
  web = callPackage ./web.nix { inherit nodejs pnpm fetchFromGitHub; };
in
buildGoModule rec {
  inherit pname version src vendorHash;

  ldflags = [ "-s" "-w" "-X main.commit=${src.rev}" "-X main.tag=${version}" ];

  postPatch = ''
    cp -r ${web}/share/autobrr-web/* web/dist/
  '';

  meta = {
    description = "Modern, easy to use download automation for torrents and usenet";
    homepage = "https://github.com/autobrr/autobrr";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ adtya ];
    mainProgram = "autobrr";
  };
}
