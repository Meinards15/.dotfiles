{ pkgs, lib, config, ... }:

let
    user     = "thadfake";
    # Absolute path to the dotfiles repo on the live system.
    dotfiles = "/home/${user}/nixos-dotfiles/configs/.config";

    # Configs to symlink: ~/.config/<name> → dotfiles/<subpath>
    configs = {
        nvim     = "nvim";
        niri     = "niri";
        noctalia = "noctalia";
        # kitty  = "kitty";
        # dunst  = "dunst";
    };

in
{
    ## Wire home-manager into this NixOS system
    home-manager = {
        useGlobalPkgs   = true;
        useUserPackages = true;
        users.${user} = { config, lib, pkgs, ... }: {
            imports = [ ../thadfake/pkgs.nix ];

            ## Session Variables
            home.sessionVariables = {
                EDITOR = "nvim";

                XDG_DATA_HOME       = "$HOME/.local/share";
                XDG_CONFIG_HOME     = "$HOME/.config";
                XDG_CACHE_HOME      = "$HOME/.cache";
                XDG_STATE_HOME      = "$HOME/.local/state";

                XDG_DESKTOP_DIR     = "$HOME/Desktop";
                XDG_DOCUMENTS_DIR   = "$HOME/Documents";
                XDG_DOWNLOAD_DIR    = "$HOME/Downloads";
                XDG_PICTURES_DIR    = "$HOME/Pictures";
                XDG_VIDEOS_DIR      = "$HOME/Videos";
                XDG_MUSIC_DIR       = "$HOME/Music";
                XDG_TEMPLATES_DIR   = "$HOME/Templates";
                XDG_PUBLICSHARE_DIR = "$HOME/Public";
                XDG_DOCS_DIR        = "$HOME/Documentation";
                XDG_PROJECTS_DIR    = "$HOME/Projects";

                ## Wayland / Qt / Electron
                QT_QPA_PLATFORM                     = "wayland";
                QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                ELECTRON_OZONE_PLATFORM_HINT        = "auto";
                GDK_BACKEND                         = "wayland,x11";
                SDL_VIDEODRIVER                     = "wayland,x11";
                MOZ_ENABLE_WAYLAND                  = "1";
                CLUTTER_BACKEND                     = "wayland";

                NIXPKGS_ALLOW_UNFREE = "1";
            };

            ## Identity
            home.username      = user;
            home.homeDirectory = "/home/${user}";
            home.stateVersion  = "25.11";

            ## Font config (HM option — not NixOS fonts.*)
            fonts.fontconfig = {
                enable = true;
                defaultFonts = {
                    monospace = [ "JetBrainsMono Nerd Font" ];
                    sansSerif = [ "Noto Sans" ];
                    serif     = [ "Noto Serif" ];
                    emoji     = [ "Noto Color Emoji" ];
                };
            };

            ## Shell
            programs.bash = {
                enable = true;
                shellAliases = {
                    ls   = "eza -a --icons --group-directories-first";
                    ll   = "eza -la --icons --group-directories-first";
                    lt   = "eza -T --icons";
                    cat  = "bat --paging=never";
                    grep = "rg";
                    find = "fd";

                    nrs      = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#maquina";
                    nrb      = "sudo nixos-rebuild boot   --flake ~/nixos-dotfiles#maquina";
                    nrt      = "sudo nixos-rebuild test   --flake ~/nixos-dotfiles#maquina";
                    nrs-snap = "rebuild-snap switch";
                    ngc      = "nix-collect-garbage -d";
                    nfu      = "nix flake update";
                    nsh      = "nix-shell";
                };
                initExtra = ''
                    export PATH=$(printf '%s\n' "$PATH" | awk -v RS=: '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
                '';
            };

            ## Git
            programs.git = {
                enable    = true;
                userName  = "Meinards15";
                userEmail = "meinards15@gmail.com";
                extraConfig = {
                    init.defaultBranch   = "main";
                    pull.rebase          = false;
                    push.autoSetupRemote = true;
                };
            };

            ## XDG — live symlinks to repo configs
            xdg = {
                enable = true;
                userDirs = {
                    enable            = true;
                    createDirectories = true;
                };
                configFile = builtins.mapAttrs (name: subpath: {
                    source    = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${subpath}";
                    recursive = true;
                }) configs;
            };

            programs.home-manager.enable = true;
        };
    };
}
