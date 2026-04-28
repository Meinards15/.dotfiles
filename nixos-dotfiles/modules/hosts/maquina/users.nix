# modules/hosts/maquina/users.nix — user accounts and custom groups
#
# ─── Custom Groups ────────────────────────────────────────────────────────────
#
#   isolpkg
#     • Full control over app containers in /opt/packages/pkg-sandbox
#     • Can add / remove / start / stop / modify any container therein
#     • No access to the rest of /opt/packages
#     • Map: assigned to users who manage sandboxed application containers
#
#   syspkg
#     • Full write access to /opt/packages/* (appimages, wine, scripts, flatpak)
#     • EXCEPT /opt/packages/pkg-sandbox (that is isolpkg territory)
#     • Map: power users who install non-Nix software system-wide  [ @pkgs subvol ]
#
#   sandbox
#     • Identity used INSIDE a pkg-sandbox container
#     • Has no host filesystem access — all access is mediated by bubblewrap
#     • Never assigned to a real login account; only to sandboxed processes
#
# ─── Permission enforcement ───────────────────────────────────────────────────
# Actual directory permissions are set in pkgs.nix via systemd.tmpfiles.rules.
# Group membership here grants the OS identity; tmpfiles sets the ACL target.

{ pkgs, lib, ... }:

{
    users.mutableUsers = false;     # all accounts declared here — no `passwd` drift

    users = {
        # Root account locked (no password login; use doas/sudo from wheel)
        users.root = {
            # hashedPassword = "!";
            password = "1331";
        };

        # Primary user
        users.thadfake = {
            isNormalUser    = true;
            description     = "Default User";
            home            = "/home/thadfake";
            password        = "1331";
            extraGroups     = [
                "wheel"           # doas / sudo
                "audio"           # PipeWire / ALSA
                "video"           # GPU / camera
                "input"           # keyboard / mouse raw devices
                "networkmanager"  # manage networks without root
                "storage"         # mount removable drives
                "bluetooth"       # bluetoothctl without root
                "syspkg"          # write to /opt/packages (except pkg-sandbox)
                "isolpkg"         # manage /opt/packages/pkg-sandbox containers
            ];
            shell = pkgs.bash;
        };
    };

    ## Custom Groups
    users.groups = {
        thadfake = {};
	isolpkg  = {};
        syspkg   = {};
        sandbox  = {};
    };
}
