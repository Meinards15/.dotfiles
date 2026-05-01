# modules/users/thadfake/pkgs.nix — user-level packages
{ config, pkgs, lib, ... }:
{
    home.packages = with pkgs; [
        neovim
        kitty
        tmux
        yazi
        thunar
        swaybg
        wl-clipboard
        cliphist
        dunst
        libnotify
        fuzzel
        nwg-look
        papirus-icon-theme
        imv
        networkmanager-applet
        keepassxc
        # mpv    — via mpv-sandbox wrapper (pkg-sandbox.nix)
        # zathura — via zathura-sandbox wrapper (pkg-sandbox.nix)
    ];
}
