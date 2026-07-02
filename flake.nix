{
  description = "Non-NixOS VPS airport node helper using sing-box VLESS Reality";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          airport-node-runtime = pkgs.symlinkJoin {
            name = "airport-node-runtime";
            paths = [
              pkgs.busybox
              pkgs.sing-box
              pkgs.qrencode
            ];
          };

          airport-node-init = pkgs.writeShellApplication {
            name = "airport-node-init";
            runtimeInputs = [
              pkgs.busybox
              pkgs.coreutils
              pkgs.gawk
              pkgs.gnugrep
              pkgs.gnused
              pkgs.jq
              pkgs.openssl
              pkgs.qrencode
              pkgs.sing-box
              pkgs.systemd
            ];
            text = builtins.readFile ./scripts/airport-node-init.sh;
          };

          airport-node-info = pkgs.writeShellApplication {
            name = "airport-node-info";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.qrencode
            ];
            text = builtins.readFile ./scripts/airport-node-info.sh;
          };
        in
        {
          inherit airport-node-init airport-node-info airport-node-runtime;
          default = airport-node-info;
        });

      apps = forAllSystems (system:
        let
          pkgs = self.packages.${system};
        in
        {
          airport-node-init = {
            type = "app";
            program = "${pkgs.airport-node-init}/bin/airport-node-init";
          };

          airport-node-info = {
            type = "app";
            program = "${pkgs.airport-node-info}/bin/airport-node-info";
          };

          default = self.apps.${system}.airport-node-info;
        });
    };
}
