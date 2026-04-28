# modules/hosts/maquina/default.nix — host entry point
{ ... }:
{
    imports = [
        ./configuration.nix
        ../../users/thadfake/home-manager.nix
    ];
}
