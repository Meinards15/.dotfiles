########################################
########################################
###                                  ### 
###   @           --> /              ###
###   @home       --> /home          ###
###   @nix        --> /nix           ###
###   @snapshots  --> /.snapshots    ###
###   @pkgs       --> /opt/packages  ###
###   @log        --> /var/log       ###
###   @cache      --> /var/cache     ###
###                                  ###
########################################
########################################

# Windows HDD UUID: 3825-E29D  (FAT32 ESP on the Windows drive)
# Linux  HDD UUID:  9522-AC86  (FAT32 ESP on this NixOS drive — /boot)

{ inputs, config, lib, pkgs, modulesPath, ... }:

let
    # compress=zstd:1  - transparent compression (level 1 = fast, good ratio)
    # noatime          - don't update access timestamps (reduces write pressure)
    # space_cache=v2   - faster free-space lookups
    # discard=async    - SSD TRIM issued asynchronously (safer than sync)
    btrfsOpts = [ "compress=zstd:1" "noatime" "space_cache=v2" "discard=async" ];
in

{
    imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.impermanence.nixosModules.impermanence
    ];

    ## Kernel Modules
    boot.initrd.availableKernelModules = [
        "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"
    ];
    boot.initrd.supportedFilesystems = [ "btrfs" ];
    boot.initrd.kernelModules = [ "btrfs" "dm-mod" "dm-crypt" ];
    boot.kernelModules        = [ "kvm-amd" ];
    boot.extraModulePackages  = [ ];

    ## CPU Microcode
    hardware.cpu.amd.updateMicrocode =
        lib.mkDefault config.hardware.enableRedistributableFirmware;
    # hardware.cpu.intel.updateMicrocode =
    #   lib.mkDefault config.hardware.enableRedistributableFirmware;

    ## Kernel
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.default ];
    boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    # boot.kernelPackages = pkgs.linuxPackages_latest;

    ## GRUB
    boot.loader = {
        efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint     = "/boot";
        };
        grub = {
            enable       = true;
            efiSupport   = true;
            device       = "nodev";     # pure UEFI - no MBR installation
            useOSProber  = true;
            # theme        = null;
            # font         = "";
            # splashImage  = null;
            extraEntries = ''
                # Manual fallback entry for the Windows EFI partition
                menuentry "Windows (manual)" {
                    search --set=root --fs-uuid 3825-E29D
                    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
                }
            '';
        };
    };

    ## Filesystem Template Setup
    fileSystems = {
        "/boot" = {
            device  = "/dev/disk/by-uuid/9522-AC86";
            fsType  = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };

        "/persistent" = {
            device  = "/dev/disk/by-label/nixos";
            neededForBoot = true;
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@" ];
        };

        "/" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@" ];
        };

        "/home" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@home" ];
        };

        "/nix" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = [ "noatime" "space_cache=v2" "discard=async" "subvol=@nix" "nodatacow" ];
        };

        "/.snapshots" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@snapshots" ];
        };

        "/opt/packages" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@pkgs" ];
        };

        "/var/log" = {
            device         = "/dev/disk/by-label/nixos";
            fsType         = "btrfs";
            options        = btrfsOpts ++ [ "subvol=@log" ];
            neededForBoot  = true;
        };

        "/var/cache" = {
            device  = "/dev/disk/by-label/nixos";
            fsType  = "btrfs";
            options = btrfsOpts ++ [ "subvol=@cache" ];
        };
        ## Auto-Mounting Drives
        # lsblk -f
        #"/mnt/NAS" = {
        #    device  = "/dev/disk/by-uuid/C3548E44E9DC46C6";
        #    fsType  = "ntfs-3g";
        #    options = [ "defaults" "nofail" "noatime" "x-systemd.automount" ];
        #};
    };

    ## Zram
    zramSwap = {
        enable        = true;
        priority      = 100;
        algorithm     = "lz4";
        memoryPercent = 50;
    };

    ## Platform
    networking.useDHCP   = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
        os-prober
        btrfs-prog
        compsize
        ntfs3g
    ];
}
