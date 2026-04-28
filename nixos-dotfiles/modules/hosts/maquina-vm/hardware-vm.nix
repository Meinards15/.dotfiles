# modules/hosts/maquina-vm/hardware-vm.nix
# QEMU/KVM VM hardware — simple virtio disk, no btrfs subvolumes needed.
{ modulesPath, lib, pkgs, ... }:
{
    imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

    boot.initrd.availableKernelModules = [
        "xhci_pci" "virtio_pci" "virtio_blk" "virtio_scsi" "ahci" "sd_mod"
    ];
    boot.initrd.kernelModules = [];
    boot.kernelModules        = [ "kvm-intel" "kvm-amd" ];
    boot.extraModulePackages  = [];

    ## GRUB
    boot.loader = {
        efi.canTouchEfiVariables = true;
        grub = {
            enable     = true;
            efiSupport = true;
            device     = "nodev";
        };
    };

    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };
    fileSystems."/boot" = {
        device = "/dev/disk/by-label/boot";
        fsType = "vfat";
    };

    ## Create /opt/packages directories on ext4 (tmpfiles handles this)
    ## No btrfs subvolumes needed for the VM test

    zramSwap = {
        enable        = true;
        algorithm     = "lz4";
        memoryPercent = 50;
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    networking.useDHCP   = lib.mkDefault true;
}
