# VM Test Instructions

## Building and running the VM

On your machine (where nix + qemu are available):

```bash
# 1. Enter the dotfiles directory
cd nixos-dotfiles

# 2. Build the VM (downloads all dependencies, ~2GB first time)
nixos-rebuild build-vm --flake .#maquina-vm

# 3. Run the VM
./result/bin/run-maquina-vm-vm
#   - Default login: thadfake / 1331
#   - SSH available on localhost:2222 (QEMU user networking)
#   - Ly display manager starts on tty2
```

Alternatively, use nixos-rebuild directly:
```bash
nix build .#nixosConfigurations.maquina-vm.config.system.build.vm
./result/bin/run-maquina-vm-vm
```

## Installing on real hardware (maquina host)

### Step 1: Partition and format disk

```bash
# Boot NixOS ISO, then:
parted /dev/sdX -- mklabel gpt
parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sdX -- mkpart primary 512MiB 100%
parted /dev/sdX -- set 1 esp on

mkfs.fat -F32 -n boot /dev/sdX1
mkfs.btrfs -L nixos /dev/sdX2
```

### Step 2: Create btrfs subvolumes

```bash
mount /dev/sdX2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@pkgs
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
umount /mnt
```

### Step 3: Mount and install

```bash
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@ /dev/sdX2 /mnt

mkdir -p /mnt/{boot,home,nix,.snapshots,opt/packages,var/log,var/cache}

mount /dev/sdX1 /mnt/boot
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@home /dev/sdX2 /mnt/home
mount -o noatime,space_cache=v2,discard=async,subvol=@nix,nodatacow /dev/sdX2 /mnt/nix
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@snapshots /dev/sdX2 /mnt/.snapshots
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@pkgs /dev/sdX2 /mnt/opt/packages
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@log /dev/sdX2 /mnt/var/log
mount -o compress=zstd:1,noatime,space_cache=v2,discard=async,subvol=@cache /dev/sdX2 /mnt/var/cache

# Clone this repo into /mnt/home/thadfake
mkdir -p /mnt/home/thadfake
git clone https://github.com/Meinards15/.dotfiles /mnt/home/thadfake/nixos-dotfiles

# Update hardware.nix UUIDs to match YOUR disk
blkid  # note UUIDs
# Edit modules/hosts/maquina/hardware.nix: replace 9522-AC86 and nixos label

nixos-install --flake /mnt/home/thadfake/nixos-dotfiles/nixos-dotfiles#maquina --root /mnt
```

### Step 4: Post-install

```bash
reboot
# Login: thadfake / 1331
# Change password: passwd
```
