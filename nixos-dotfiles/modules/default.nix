# modules/default.nix — flake-parts entry point
#
# ─── How this works ───────────────────────────────────────────────────────────
# flake-parts calls this file and passes `inputs` via specialArgs.
# We discover every subdirectory under ./hosts/ automatically and build one
# nixosSystem per host — no manual registration needed when adding new machines.
#
# Each host directory must export a flake-parts module (the pattern used
# throughout this repo: `{ self, inputs, ... }: { flake.nixosModules.X = ... }`).
#
# ─── Adding a new host ────────────────────────────────────────────────────────
#   mkdir -p modules/hosts/myhostname
#   cp -r modules/hosts/maquina modules/hosts/myhostname
#   # edit hardware.nix, configuration.nix …
#   nixos-rebuild switch --flake .#myhostname

{ self, inputs, lib, ... }:

let
    systemsDir = ./hosts;

    # Collect only directories (each dir = one host)
    hostDirs = lib.filterAttrs
        (_: type: type == "directory")
        (builtins.readDir systemsDir);

    # Build a NixOS system for a single host directory
    mkSystem = name: inputs.nixpkgs.lib.nixosSystem {
        system  = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [
            # Import everything inside the host directory via default.nix or
            # direct path — each host exports its own flake module.
            (systemsDir + "/${name}")
            inputs.home-manager.nixosModules.home-manager
        ];
    };

in
{
    # Expose as flake outputs: nixosConfigurations.<hostname>
    flake.nixosConfigurations = builtins.mapAttrs
        (name: _: mkSystem name)
        hostDirs;
}
