{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?ref=main";
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          autobrr = pkgs.callPackage ./packages/autobrr { };
          ezbookkeeping = pkgs.callPackage ./packages/ezbookkeeping { };
        };
      }
    ) // {
    nixosModules.default = import ./modules;
    overlays.default = import ./overlay.nix;
  };
}
