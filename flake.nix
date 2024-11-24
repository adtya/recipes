{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils?ref=main";
  };
  outputs = { nixpkgs, flake-utils, ... }:
    let
      pkgs_x86_64-linux = import nixpkgs {
        system = "x86_64-linux";
      };
      pkgs_aarch64-linux = import nixpkgs {
        system = "aarch64-linux";
      };
    in
    {
      nixosModules.default = import ./modules;
      overlays.default = import ./overlay.nix;
      packages.x86_64-linux.autobrr = pkgs_x86_64-linux.callPackage ./packages/autobrr { };
      packages.aarch64-linux.autobrr = pkgs_aarch64-linux.callPackage ./packages/autobrr { };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
