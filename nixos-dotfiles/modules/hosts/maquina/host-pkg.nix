# modules/hosts/maquina/pkgs.nix — nix daemon, system packages, @pkgs layout
#
# ─── Package channels ─────────────────────────────────────────────────────────
# Default channel: nixpkgs (unstable). To pull a single package from another
# channel, pass `inputs` via specialArgs and use:
#   inputs.nixpkgs-stable.legacyPackages.x86_64-linux.<pkg>
#
# ─── @pkgs subvolume directory layout ────────────────────────────────────────
# /opt/packages/
#   appimages/        — AppImage bundles              (owner: thadfake:syspkg  0770)
#   scripts/          — standalone shell scripts      (owner: thadfake:syspkg  0770)
#   flatpak/          — Flatpak data / overrides      (owner: thadfake:syspkg  0770)
#   wine/             — Wine prefixes / games         (owner: thadfake:syspkg  0770)
#   pkg-sandbox/      — bubblewrap container roots    (owner: thadfake:isolpkg 0770)
#     <container>/
#       rootfs/       — container overlay / bind tree
#       home/         — container home directory
#       run           — launcher script (chmod +x)
#   users/
#     thadfake/       — user-specific installs        (owner: thadfake         0700)

{ config, pkgs, lib, inputs, ... }:

{
    # ── Nix Daemon Configuration ───────────────────────────────────────────────
    nix = {
        settings = {
            experimental-features = [ "nix-command" "flakes" ];
            # Deduplicate identical files in the store with hard links
            auto-optimise-store = true;
            # Binary caches — add custom cache servers here
            substituters = [
                "https://cache.nixos.org"
                # "https://nix-community.cachix.org"
                "https://niri.cachix.org"
                "https://vicinae.cachix.org"
            ];
            trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                # "nix-community.cachix.org-1:mB9FSh9qf2dde0tzXLysoVUL0HZw/FE+g4sM3g4XYao="
                "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
                "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
            ];
            # Allow the primary user to add trusted substituters without root
            trusted-users = [ "root" "thadfake" ];
        };

        ## Cleaning Old PKGS
        gc = {
            automatic = true;
            dates     = "weekly";
            options   = "--delete-older-than 14d";  # keep 2 weeks of generations
        };

        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = lib.mkDefault [ "nixpkgs=${inputs.nixpkgs}" ];
    };

    ## System PKGS
    environment.systemPackages = with pkgs; [
        ## CLI Utilities
        ripgrep         # fast grep (rg)
        wget            # HTTP downloader
        git             # version control
        coreutils       # ls, cp, mv, … (GNU)
        util-linux      # mount, lsblk, kill, …
        procps          # ps, top, vmstat
        psmisc          # pstree, killall, fuser
        findutils       # find, xargs
        gawk            # awk
        file            # identify file types
        tree            # directory tree view
        bat             # cat with syntax highlight
        eza             # modern ls replacement
        fd              # fast find alternative
        jq              # JSON processor
        yq-go           # YAML / JSON / TOML processor
        sd              # sed-like find-and-replace
        lshw            # hardware information
        inxi            # system information summary
        man             # manual pages
        less            # pager
        socat           # socket relay (useful for proxying)
        iproute2        # ip, ss, tc
        ## TUI Tools
        btop            # interactive process/resource monitor
        iotop           # I/O monitor (requires root/sudo)
        lm_sensors      # CPU / board temperature readings
        smartmontools   # SMART disk health
        alacritty       # backup terminal (if kitty unavailable)
        vim             # backup editor (always present)

        ## Development
        lazygit         # TUI git client
        gcc             # C / C++ compiler
        openssh         # ssh client + keygen

        ## Archives & Compression
        gzip bzip2 xz zstd lz4
        zip unzip unrar gnutar

        ## Encryption / Secrets
        gnupg           # GPG key management
        age             # modern file encryption (agenix uses this)
        pass            # password-store (GPG-backed)

        ## Wayland Stack
        xwayland                # XWayland compatibility layer
        xwayland-satellite      # rootless XWayland for niri
        wl-clipboard            # wl-copy / wl-paste
        xdg-utils               # xdg-open, xdg-mime, …
        shared-mime-info        # MIME database

        ## Display Manager
        ly                      # TTY-based session manager (greeter)

        ## Desktop
        niri                    # Wayland compositor (scrollable tiling)

        ## os-prober (needed by GRUB to find Windows entry)
        os-prober

        ## Fonts
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        # Custom repo example — uncomment once custom-repo input is configured:
        # custom-repo.packages.x86_64-linux.pkgTest
    ];

    nixpkgs.config.allowUnfree = true;

    ## Programs Config 
    programs = {
        # AppImage support — binfmt_misc so AppImages run like native executables
        appimage = {
            enable  = true;
            binfmt  = true;
        };
        # dconf — needed for GTK theme settings and some Wayland portals
        dconf.enable = true;
        # Niri Wayland compositor — registers the niri session in Ly
        niri.enable = true;
        # GnuPG agent (SSH key support)
        gnupg.agent = {
            enable           = true;
            enableSSHSupport = true;
        };
    };

    # ── @pkgs Subvolume Directory Layout ─────────────────────────────────────
    # systemd-tmpfiles creates these at activation time if they don't exist.
    # Format: "TYPE PATH MODE USER GROUP AGE"
    #
    # Group permissions:
    #   syspkg  → all of /opt/packages/* (except pkg-sandbox)
    #   isolpkg → /opt/packages/pkg-sandbox only
    systemd.tmpfiles.rules = [
        #  type  path                                  mode   user       group     age
        "d /opt/packages                               0755   root       root       -"
        "d /opt/packages/appimages                     0770   thadfake   syspkg     -"
        "d /opt/packages/scripts                       0770   thadfake   syspkg     -"
        "d /opt/packages/flatpak                       0770   thadfake   syspkg     -"
        "d /opt/packages/wine                          0770   thadfake   syspkg     -"
        # pkg-sandbox: isolpkg group only (no syspkg access)
        "d /opt/packages/pkg-sandbox                   0770   thadfake   isolpkg    -"
        # Per-user install directory
        "d /opt/packages/users                         0755   root       root       -"
        "d /opt/packages/users/thadfake                0700   thadfake   thadfake   -"
    ];
}
