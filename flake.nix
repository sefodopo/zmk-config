{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix-stm = {
      url = "git+file:///home/joshua/src/zmk-nix?ref=bin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix/main";
      #url = "github:sefodopo/zmk-nix/studio";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      zmk-nix,
      zmk-nix-stm,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs (
        (nixpkgs.lib.attrNames zmk-nix-stm.packages) ++ nixpkgs.lib.attrNames zmk-nix.packages
      );
      baseFirmware = {
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

        meta = {
          description = "ZMK firmware";
          license = nixpkgs.lib.licenses.mit;
          platforms = nixpkgs.lib.platforms.all;
        };
      };
    in
    {
      packages = forAllSystems (system: rec {
        default = firmware;

        firmware-stm = zmk-nix-stm.legacyPackages.${system}.buildSplitKeyboard (
          baseFirmware
          // {
            config = "config";
            board = "keyseebee_%PART%";
            parts = [
              "left"
              "right"
            ];

            zephyrDepsHash = "sha256-vHoFIxnmxoA5LIv910h3rh1VLr1GGS7gf7X7E3idJHs=";
          }
        );
        flash-stm = zmk-nix-stm.packages.${system}.flash.override { inherit firmware; };
        update-stm = zmk-nix-stm.packages.${system}.update;

        firmware = zmk-nix.legacyPackages.${system}.buildSplitKeyboard (
          baseFirmware
          // {
            board = "nice_nano_v2";
            shield = "cosmotyl_%PART%";
            parts = [
              "dongle"
              "left"
              "right"
            ];
            #enableZmkStudio = true;

            zephyrDepsHash = "sha256-vHoFIxnmxoA5LIv910h3rh1VLr1GGS7gf7X7E3idJHs=";
          }
        );
        flash = zmk-nix.packages.${system}.flash.override { inherit firmware; };
        update = zmk-nix.packages.${system}.update;

      });

      devShells = forAllSystems (system: {
        default = zmk-nix.devShells.${system}.default;
        stm = zmk-nix-stm.devShells.${system}.default;
      });
    };
}
