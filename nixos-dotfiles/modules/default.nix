{ inputs, lib, ... }:
let
    modImport = path: 
        if builtins.pathExists path 
        then [ path ] else [ ];
in
{
    imports = 
        ## /hosts/*
        modImport ./hosts/maquina/configuration.nix ++
        modImport ./hosts/maquina-vm/configuration.nix ++
        ## /users/*
        modImport ./users/thadfake/home.nix;
}
