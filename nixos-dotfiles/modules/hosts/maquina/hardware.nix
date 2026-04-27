{ self, inputs, ... }: {
    flake.nixosModules.maquinaHardware = { config, lib, pkgs, modulesPath, ... }: {
        imports = [
            (modulesPath + "/installer/scan/not-detected.nix")
        ];

        boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-amd" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
            device = "/dev/disk/by-uuid/7fd891d4-5e7b-4176-a0fc-1eae2e2fbf25";
            fsType = "ext4";
        };

        fileSystems."/boot" = {
            device = "/dev/disk/by-uuid/9522-AC86";
            fsType = "vfat";
            options = [ "fmask=0022" "dmask=0022" ];
        };

        swapDevices = [
            { device = "/dev/disk/by-uuid/3163ee5a-a18b-43dc-81b7-b0a10f78ec40"; }
        ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
