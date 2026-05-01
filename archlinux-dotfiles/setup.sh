#!/bin/bash

# git clone -b setup https://github.com/meinards15/.dotfiles.git

pacman -Sy git fzf

## Before Installation
# SSH Setup Input
systemctl enable sshd

# sysInfo = ()

echo "Setup root password for remote connection"
passwd

ip a

read -rp "Press Enter to continue..."
clear

## Installation Input
# Keymaps
keymap=$(localectl list-keymaps | fzf --layout=reverse-list --prompt="Selected Keymap=" --header="Showing All Keyboard Keymaps Avaliable")
if [ -n "$keymap" ]; then
    loadkeys "$keymap"
    echo $keymap
fi

sleep 2

# Disk Partition
diskPart() {

while true; do
    clear
    diskSel=$(lsblk -f)
    echo "Available disks:"
    echo "$diskSel"

    read -rp "Select disk: " input

    echo "$input will be wiped. Are you sure? [Y/N]"
    read -n 1 -r confirm
    echo

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Proceeding..."
        mkdir -p /mnt/{home,pkgs,var/cache/log,.snapshots}



        sudo mount /dev/$input

        part_num=3

if [[ "$input" =~ (nvme|mmcblk) ]]; then
    partition="/dev/${input}p${part_num}"
else
    partition="/dev/${input}${part_num}"
fi

mount "$partition" /mnt

        sudo mkfs.brts 
        break
    else
        echo "Restarting selection..."
    fi

done
}

diskPart

## Boot Setup
bootType="/sys/firmware/efi/fw_platform_size"
case "$bootType" in
  "64")
    # sysInfo.add("Boot Type: UEFI x64 64-bits")
    mkdir -p /mnt/boot/efi
    ;;
  "32")
    # sysInfo.add("Boot Type: UEFI IA32 32-bits")
    mkdir -p /mnt/boot/efi
    ;;
  *)
    # sysInfo.add("Boot Type: BIOS/CSM")
    mkdir -p /mnt/boot
    ;;
esac










### After Instalation

## Dotfiles Import
cd $HOME
# git clone -b testing https://github.com/meinards15/.dotfiles.git
git clone https://github.com/meinards15/.dotfiles.git

dotfilesDir="~/.dotfiles/archlinux/"

# Dir Check
if [ !$dotfilesDir ]; then
    echo "Ensure '.dotfiles' Directory is inside $HOME"
    exit 0;
fi

## Symlink Setup
cd "$DOTFILES/configs"

config=(
    "./config/nvim"
    ".bashrc"
    ".bash_profile"
)

for i in "${config[@]}"; do
    if [ -e "$HOME/$(basename i)" ] || [ -L "$HOME/$(basename i)" ]; then
        echo "Overwriting $(basename i)"
        rm -r "$HOME/$(basename i)"
        ln -s "$dotfilesDir/$i" "$HOME/$(basename "$i")"
   else
        echo "Stabilished $i Symlink in $HOME"
        ln -s "$dotfilesDir/$i" "$HOME/$(basename "$i")"
    fi
done

## Pacman Packages Installation
sudo pacman -S --needed - > "$(dotfilesDir)/pacman-pkgs"

## Package Configs
rustup default stable


## Paru Setup
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

