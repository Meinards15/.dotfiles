# modules/hosts/maquina-vm/default.nix
# VM test host — uses identical modules to maquina but with
# VM-safe hardware (ext4 root, no btrfs subvols, QEMU VirtIO).
# Boot with: nixos-rebuild build-vm --flake .#maquina-vm
{ ... }:
{
    imports = [
        ./hardware-vm.nix
        ../maquina/pkgs.nix
        ../maquina/hardening.nix
        ../maquina/users.nix
        ../maquina/snapshots.nix
        ../maquina/pkg-sandbox.nix
        ../maquina/network.nix
        ../maquina/configuration-vm.nix
        ../../../users/thadfake/home-manager.nix
    ];
}
