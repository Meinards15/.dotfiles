# modules/hosts/maquina-vm/configuration-vm.nix
# VM-specific overrides — same as maquina/configuration.nix but without
# btrfs-specific snapper configs (no subvolumes in VM).
{ pkgs, lib, config, ... }:
{
    networking.hostName = "maquina-vm";

    time.timeZone      = "America/Sao_Paulo";
    console.keyMap     = "us";
    i18n.defaultLocale = "en_US.UTF-8";

    networking.networkmanager.enable = true;

    environment.variables = {
        EDITOR = "nvim";
        XDG_DATA_DIRS   = lib.mkDefault "/usr/local/share:/usr/share";
        XDG_CONFIG_DIRS = lib.mkDefault "/etc/xdg";
    };

    services = {
        dbus.enable     = true;
        libinput.enable = true;
    };

    ## Display Manager - Ly
    services.displayManager.ly = {
        enable   = true;
        settings.tty = 2;
    };
    systemd.services."getty@tty2".enable = false;

    ## Audio
    security.rtkit.enable = true;
    services.pipewire = {
        enable             = true;
        alsa.enable        = true;
        alsa.support32Bit  = true;
        pulse.enable       = true;
        jack.enable        = false;
        wireplumber.enable = true;
    };

    ## Bluetooth (may not work in VM but won't fail boot)
    hardware.bluetooth.enable = false;

    ## Time
    services.timesyncd.enable = true;

    ## Portal
    xdg.portal = {
        enable       = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
        config.common.default = "*";
    };

    ## VM convenience: enable SSH for easier access
    services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
        settings.PasswordAuthentication = true;
    };
    networking.firewall.allowedTCPPorts = [ 22 ];

    ## Disable snapper in VM (no btrfs subvols)
    services.snapper.configs = lib.mkForce {};

    ## System fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
    ];

    system.stateVersion = "25.11";
}
