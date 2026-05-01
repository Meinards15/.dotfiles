{ pkgs, lib, ... }:

{
    users.mutableUsers = true;

    users = {
        users = {
            root = {
                hashedPassword = "$6$JUFA0urXhkFeYtUr$eMB5YQzrFHhB/pC8N2cqFa1kXk0f8oHLGthkhss4altOXkvAs3rihKcIUISei90NayCC.Ss0x.Wi..ighKJcc1";
            };
            ## ../../users/thadfake
            thadfake = {
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
    };

    ## Custom Groups
    users.groups = {
        isolpkg  = {};
        syspkg   = {};
        sandbox  = {};
    };
}
