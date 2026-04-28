# modules/hosts/maquina/configuration.nix — core system configuration
#
# ─── Module map ───────────────────────────────────────────────────────────────
#   hardware.nix      — filesystems, bootloader, kernel modules, zram
#   pkgs.nix          — nix daemon settings, system packages, programs
#   hardening.nix     — kernel sysctl, seccomp, apparmor, audit, polkit
#   users.nix         — user accounts, groups (sandbox / syspkg / isolpkg)
#   snapshots.nix     — snapper btrfs snapshot schedules
#   pkg-sandbox.nix   — bubblewrap app container profiles + wrappers
#   network.nix       — VPN / Tor / proxy networking

{ self, inputs, pkgs, lib, config, ... }:

{
    imports = [
        ./hardware.nix
        ./pkgs.nix
        ./hardening.nix
        ./users.nix
        ./snapshots.nix
        ./pkg-sandbox.nix
        ./network.nix
    ];

    ## Hostname 
    networking.hostName = "maquina";

    ## UTC & Keyboard
    time.timeZone       = "America/Sao_Paulo";
    console.keyMap      = "us";
    i18n.defaultLocale  = "en_US.UTF-8";

    ## Network Manager
    networking.networkmanager.enable = true;
    # Proxy — uncomment and fill in if behind a corporate proxy.
    # networking.proxy.default  = "http://user:password@proxy:port/";
    # networking.proxy.noProxy  = "127.0.0.1,localhost,internal.domain";

    ## System Environment Variables 
    environment.variables = {
        EDITOR = "nvim";

        # XDG base dirs at system level (user overrides in home-manager)
        XDG_DATA_DIRS   = lib.mkDefault "/usr/local/share:/usr/share";
        XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";
    };

    ## General Service Setup
    services = {
        dbus.enable    = true;      # inter-process messaging bus
        libinput.enable = true;     # touchpad / pointer input
    };

    ## Display Manager - [ Ly ]
    services.displayManager.ly = {
        enable = true;
        settings = {
            tty            = lib.mkForce 2;
            lock_timeout   = 0;
            save           = true;  # remember last session in /var/cache/ly
            animation      = 0;     
            vi_mode        = false;
            hide_borders   = false;
            clear_password = true;
        };
    };
    ## + ly in tty2 | - tty in tty2 
    systemd.services."getty@tty2".enable = false;

    ## Desktop Enviroment
    # [ Niri | Wayland ]


    ## Desktop Enviroment
    # [ QTile | X11 ]


    ## Audio Manager - [ Pipewire ]
    services.pipewire = {
        enable              = true;
        alsa.enable         = true;
        alsa.support32Bit   = true;
        pulse.enable        = true;
        jack.enable         = false;
        wireplumber.enable  = true;
    };
    security.rtkit.enable   = true;

    ## Bluetooth Manager
    hardware.bluetooth = {
        enable     = true;
        powerOnBoot = true;
        settings = {
            Policy.AutoEnable = "true";
            General = {
                # ControllerMode  = "bredr"; # classic
                FastConnectable = "true";
                Experimental    = "true";   # bt5 features 
            };
        };
    };
    services.blueman.enable = true;

    ## Time Sync
    services.timesyncd = {
        enable  = true;
        servers = [
            "0.br.pool.ntp.org"
            "1.br.pool.ntp.org"
            "0.pool.ntp.org"
            "1.pool.ntp.org"
        ];
    };

    ## XDG Desktop Portal
    xdg.portal = {
        enable                  = true;
        extraPortals            = with pkgs; [
            xdg-desktop-portal-gtk 
            # xdg-desktop-portal-gnome
        ];
        config.common.default   = "*";
    };

    ## Polkit
    # polkit-gnome is spawned from niri config.kdl spawn-at-startup.
    security.polkit.enable = true;

    ## SSH Setup
    # services.openssh = {
    #     enable                  = true;
    #     settings.PasswordAuthentication = false;
    #     settings.PermitRootLogin        = "no";
    # };

    system.stateVersion = "25.11";
}
