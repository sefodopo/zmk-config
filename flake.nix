{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "/home/joshua/src/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (nixpkgs.lib.attrNames zmk-nix.packages);
    in
    {
      packages = forAllSystems (system: rec {
        default = firmware;

        firmware = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "firmware";

          src = nixpkgs.lib.sourceFilesBySuffices self [
            ".board"
            ".cmake"
            ".conf"
            ".defconfig"
            ".dts"
            ".dtsi"
            ".json"
            ".keymap"
            ".overlay"
            ".shield"
            ".yml"
            "_defconfig"
          ];

          board = "keyseebee_rev4";
          #shield = "lily58_%PART%";

          zephyrDepsHash = "sha256-oFq//NA1dUXYCnT1KkSWqQp4yrxgAbBDsmlTtL//0wY=";

          meta = {
            description = "ZMK firmware";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
        update = zmk-nix.packages.${system}.update;
      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
      });
    };
}
