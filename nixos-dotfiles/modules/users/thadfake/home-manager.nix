# modules/users/thadfake/home-manager.nix — Home Manager configuration
#
# ─── How symlinks work ────────────────────────────────────────────────────────
# Config files live in the repo at configs/.config/<app>/.
# Home Manager receives a symlink pointing at the live git checkout so edits
# to the repo are immediately reflected without a rebuild.
#
# The symlink target is built from config.home.homeDirectory so it is correct
# on any machine that shares this user module.
#
# ─── Adding a new app config ──────────────────────────────────────────────────
# 1. Drop the config dir under configs/.config/<appname>/
# 2. Add `<appname> = "<appname>";` to the `configs` attrset below
# 3. `home-manager switch` — done

{ self, config, inputs, ... }:

let
    user     = "thadfake";
    dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/configs/.config";

    # mkOutOfStoreSymlink: symlink that points at a mutable path (the git repo)
    # rather than copying files into the Nix store on each rebuild.
    lnLive = path: config.lib.file.mkOutOfStoreSymlink path;

    # Map of XDG config dir name → subdirectory name under configs/.config/
    # Add entries here to symlink new app configs.
    configs = {
        nvim  = "nvim";
        niri  = "niri";
        # kitty = "kitty";    # uncomment when kitty config is added
        # dunst = "dunst";
    };

in
{
    flake.nixosModules.thadfake-config = { pkgs, lib, ... }: {
        imports = [ ./pkgs ];

        ## User Environment Variables
        home.sessionVariables = {
            EDITOR = "nvim";

            # XDG base directories
            XDG_DATA_HOME       = "$HOME/.local/share";
            XDG_CONFIG_HOME     = "$HOME/.config";
            XDG_CACHE_HOME      = "$HOME/.cache";
            XDG_STATE_HOME      = "$HOME/.local/state";

            # XDG user directories
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

            # Wayland / Qt / Electron hints
            QT_QPA_PLATFORM                  = "wayland";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
            ELECTRON_OZONE_PLATFORM_HINT     = "auto";
            GDK_BACKEND                      = "wayland,x11";
            SDL_VIDEODRIVER                  = "wayland,x11";
            MOZ_ENABLE_WAYLAND               = "1";
            CLUTTER_BACKEND                  = "wayland";

            # Nix / flake dev convenience
            NIXPKGS_ALLOW_UNFREE = "1";
        };

        ## User Setup
        home.username      = user;
        home.homeDirectory = "/home/${user}";
        home.stateVersion  = "25.11";

        ## Fonts
        fonts = {
            enableDefaultPackages = true;
            fontconfig = {
                defaultFonts = {
                    monospace = [ "JetBrainsMono Nerd Font" ];
                    sansSerif = [ "Noto Sans" ];
                    serif     = [ "Noto Serif" ];
                    emoji     = [ "Noto Color Emoji" ];
                };
            };
            packages = with pkgs; [
                fira-code
                fira-code-symbols
                noto-fonts
                noto-fonts-cjk-sans
                noto-fonts-color-emoji
                liberation_ttf
            ];
        };

        ## Shell
        programs.bash = {
            enable = true;
            shellAliases = {
                ls    = "eza -a --icons --group-directories-first";
                ll    = "eza -la --icons --group-directories-first";
                lt    = "eza -T --icons";
                cat   = "bat --paging=never";
                grep  = "rg";
                find  = "fd";

                # Nix workflow
                nrs   = "sudo nixos-rebuild switch --flake .";
                nrb   = "sudo nixos-rebuild boot --flake .";
                nrt   = "sudo nixos-rebuild test --flake .";
                nrs-snap = "rebuild-snap switch";   # rebuild + btrfs snapshot pair
                ngc   = "nix-collect-garbage -d";
                nfu   = "nix flake update";
                nsh   = "nix-shell";
            };
            initExtra = ''
                # Deduplicate $PATH
                export PATH=$(printf '%s\n' $PATH | awk -v RS=: '!seen[$0]++' | tr '\n' ':' | sed 's/:$//')
            '';
        };

        ## Git
        programs.git = {
            enable     = true;
            userName   = "Meinards15";
            userEmail  = "meinards15@gmail.com";
            extraConfig = {
                init.defaultBranch = "main";
                pull.rebase        = false;
                push.autoSetupRemote = true;
            };
        };

        ## XDG
        xdg = {
            enable = true;
            userDirs = {
                enable            = true;
                createDirectories = true;
            };
            # Each entry: ~/.config/<name> → ~/nixos-dotfiles/configs/.config/<subpath>
            configFile = builtins.mapAttrs (name: subpath: {
                source   = lnLive "${dotfiles}/${subpath}";
                recursive = true;
            }) configs;
        };


        programs.home-manager.enable = true;
    };
}
