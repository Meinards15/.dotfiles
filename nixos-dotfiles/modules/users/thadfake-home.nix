{ config, pkgs, ... }:

let
    dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/configs/.config";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
    configs = {
        nvim = "nvim";
    };
in

{
    home.username = "thadfake";
    home.homeDirectory = "/home/thadfake";
    programs.git.enable = true;
    home.stateVersion = "25.11";
    programs.bash = {
        enable = true;
        shellAliases = {
            t = "echo t";
        };
    };

    xdg.configFile = builtins.mapAttrs 
        (name: subpath: {
            source = create_symlink "${dotfiles}/${subpath}";
            recursive = true;
        })
    configs;

    home.packages = with pkgs; [
        nixpkgs-fmt
        cmake
        rofi
    ];
}
