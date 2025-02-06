{
  description = "Zoetic Chess Engine";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zig
            linuxPackages_latest.perf
          ];
        };
      }
    );
}
