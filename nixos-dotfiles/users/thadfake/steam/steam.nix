{ pkgs, lib, ... }:

{
    programs = {
        steam = {
            enable = true;
            ## 64-Bits
            package.pkgs.steam.override = with extraPkgs; [
                    ## NVIDIA
                    # bumblebee primus


                ];
            };
            ## 32-Bits
            package = pkgs.steamFull.override {
                extraPkgs = pkgs': with pkgs'; [

                ];
            };
            ## ProtonGE
            extraCompatPackages = with pkgs; [
                proton-ge-bin
            ];
        };
    }

}
