# modules/hosts/maquina/default.nix
{ config, pkgs, lib, inputs, self, ... }:

{
    imports = [
        ./configuration.nix
   ];
}
