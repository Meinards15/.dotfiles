# modules/users/thadfake/pkgs.nix — user-level packages and @pkgs user dir
#
# Packages here are installed in the user's profile (not system-wide).
# Channel usage:
#   pkgs.<name>                               — nixpkgs unstable (default)
#   inputs.nixpkgs-stable.legacyPackages…     — stable
#   inputs.nixpkgs-oldstable.legacyPackages…  — oldstable
#   inputs.custom-repo.packages…              — private repo

{ config, pkgs, lib, ... }:

{
    home.packages = with pkgs; [
        neovim
        kitty           # primary terminal
        tmux            # terminal multiplexer
        yazi            # TUI file manager
        thunar          # GUI file manager
        swaybg          # wallpaper setter (static / animated)
        wl-clipboard    # wl-copy / wl-paste
        cliphist        # clipboard history daemon + fuzzel integration
        dunst           # notification daemon
        libnotify       # notify-send command
        fuzzel          # application / run launcher (Wayland-native)
        nwg-look        # GTK theme switcher (Wayland / niri compatible)
        papirus-icon-theme
        imv             # image viewer (Wayland)
        # mpv installed via mpv-sandbox wrapper in pkg-sandbox.nix
        # zathura installed via zathura-sandbox wrapper in pkg-sandbox.nix
        networkmanager-applet   # systray NM indicator
        keepassxc       # password manager

        # oldstable example: inputs.nixpkgs-oldstable.legacyPackages.x86_64-linux.somePkg
        # custom-repo example: inputs.custom-repo.packages.x86_64-linux.customTool
    ];

    # Creates /opt/packages/users/thadfake if it doesn't exist.
    # The system-level tmpfiles in pkgs.nix creates the parent; this entry is
    # a no-op if the parent already exists, but kept here for documentation.
    systemd.user.tmpfiles.rules = [
        "d /opt/packages/users/${config.home.username} 0700 ${config.home.username} - -"
    ];
}
