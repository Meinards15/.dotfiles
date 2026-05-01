{ inputs, pkgs, lib, config, ... }:

{
    imports = [
        ../../core/virtualization.nix
        ../../core/hardware.nix
        ../../security/hardening.nix
        ../../security/network.nix
        ./backup.nix
        ./containers.nix
        ./host-pkg.nix
        ./users.nix
   ];

    ## System Info
    # Version = NixOS Version
    system.stateVersion = "25.11";
    # Hostname 
    networking.hostName = "maquina";

    ## UTC & Keyboard
    time.timeZone       = "America/Sao_Paulo";
    console.keyMap      = "us";
    i18n.defaultLocale  = "en_US.UTF-8";

    ## Network Manager
    networking.networkmanager.enable = true;

    ## Proxy
    # networking.proxy.default  = "http://user:password@proxy:port/";
    # networking.proxy.noProxy  = "127.0.0.1,localhost,internal.domain";

    ## System Environment Variables 
    environment.variables = {
        EDITOR = "nvim";
        # XDG
        XDG_DATA_DIRS   = lib.mkForce "/usr/local/share:/usr/share";
        XDG_CONFIG_DIRS = lib.mkForce "/etc/xdg";
    };

    ## General Service Setup
    services = {
        dbus.enable    = true;      # D-Bus
        libinput.enable = true;     # Touchpad Support
    };

    ## Display Manager - [ Ly ]
    services.displayManager.ly = {
        enable   = true;
        settings = {
            tty  = lib.mkForce 2;
            # Valid ly.ini keys — uncomment as needed:
            # animate        = false;
            # hide_borders   = false;
            # vi_mode        = false;
            # clear_password = true;
        };
    };
    # + ly in tty2 | - tty in tty2 
    systemd.services."getty@tty2".enable = false;

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
        config.common.default   = "gtk";
    };

    ## SSH Setup
    # services.openssh = {
    #     enable                  = true;
    #     settings.PasswordAuthentication = false;
    #     settings.PermitRootLogin        = "no";
    # };

}
