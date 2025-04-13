{
  description = "Common nix config of a couple of people";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      haumea,
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsForSystem = system: (import nixpkgs { inherit system; });
      hlib = haumea.lib;
      lib = nixpkgs.lib; # TODO extensions
    in
    {

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsForSystem system;
        in
        {
          scripts = {
            standalone = lib.mapAttrs pkgs.writeShellScript (
              hlib.load {
                src = ./scripts/standalone;
                loader = hlib.loaders.default;
                inputs = {
                  inherit pkgs lib;
                  inherit (lib) getExe getExe';
                };
              }
            ); # these are just derivations
          };
        }
      );

    };
}
