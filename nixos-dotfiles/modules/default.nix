# modules/default.nix — flake-parts entry point
#
# Auto-discovers host directories under ./hosts/ and builds one
# nixosSystem per host. No manual registration needed for new machines.
#
# Adding a new host:
#   mkdir -p modules/hosts/myhostname
#   cp -r modules/hosts/maquina modules/hosts/myhostname
#   # edit hardware.nix, configuration.nix
#   nixos-rebuild switch --flake .#myhostname

{ inputs, lib, ... }:

let
    systemsDir = ./hosts;

    hostDirs = lib.filterAttrs
        (_: type: type == "directory")
        (builtins.readDir systemsDir);

    mkSystem = name: inputs.nixpkgs.lib.nixosSystem {
        system      = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
            (systemsDir + "/${name}")
            inputs.home-manager.nixosModules.home-manager
        ];
    };

in
{
    flake.nixosConfigurations = builtins.mapAttrs
        (name: _: mkSystem name)
        hostDirs;
}
