# Bluetooth Dual-Boot Pairing Guide
# Linux (NixOS) + Windows — same device, no re-pairing

## The problem
Bluetooth uses a link key (pairing key) that is negotiated during pairing and
stored on both sides. When you pair a device in Windows and then boot Linux (or
vice versa), each OS stores a DIFFERENT key. The device only knows the most
recent key, so the other OS's key is invalid → "connection failed".

## The solution
Extract the link key Windows stored and copy it into Linux's BlueZ database.
You do this ONCE per device. After that, switching between OSes requires only
re-connecting, not re-pairing.

---

## Step-by-step

### 1. Pair the device in Linux first

```bash
bluetoothctl
  power on
  agent on
  scan on
  pair <MAC>
  connect <MAC>
  trust <MAC>
  quit
```

Write down the adapter and device MAC addresses shown:
  Adapter: XX:XX:XX:XX:XX:XX
  Device:  YY:YY:YY:YY:YY:YY

### 2. Boot into Windows and pair the SAME device

Pair it normally in Windows Bluetooth settings.

### 3. Extract the link key from the Windows registry

In Windows, open an elevated PowerShell or cmd:

```powershell
# Requires PsExec (Sysinternals) to access SYSTEM-owned registry keys.
# Download from: https://learn.microsoft.com/sysinternals/downloads/psexec

PsExec64.exe -s -i regedit
```

Navigate to:
  HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys\
    <adapter-mac-no-colons>\
      <device-mac-no-colons>

The value shown is the link key (16 bytes / 32 hex chars).
For BLE (Bluetooth Low Energy) devices, the keys are nested further under
the device address.

### 4. Update the Linux BlueZ key

Boot back into Linux. The key file is at:
  /var/lib/bluetooth/<ADAPTER_MAC>/<DEVICE_MAC>/info

Example path:
  /var/lib/bluetooth/XX:XX:XX:XX:XX:XX/YY:YY:YY:YY:YY:YY/info

Open it with root:
```bash
sudo nano /var/lib/bluetooth/XX:XX:XX:XX:XX:XX/YY:YY:YY:YY:YY:YY/info
```

Find the [LinkKey] section and replace the Key= value with the one from
Windows. For classic Bluetooth:

```ini
[LinkKey]
Key=AABBCCDDEEFF00112233445566778899
Type=4
PINLength=0
```

For BLE devices the sections are [LongTermKey] and [SlaveLongTermKey]:
```ini
[LongTermKey]
Key=AABBCCDDEEFF00112233445566778899
Authenticated=0
EncSize=16
EDiv=<value from registry>
Rand=<value from registry (convert big-endian to decimal)>
```

### 5. Reload BlueZ

```bash
sudo systemctl restart bluetooth
bluetoothctl connect <DEVICE_MAC>
```

The device should connect without re-pairing.

---

## Automating with chntpw (alternative — no Windows boot required)

If you have access to the Windows NTFS partition from Linux, you can read the
registry hive directly using `chntpw`:

```bash
# Mount Windows partition (adjust UUID)
sudo mount -o ro /dev/disk/by-uuid/3825-E29D /mnt/windows

# Read the Bluetooth keys hive
sudo chntpw -e \
  /mnt/windows/Windows/System32/config/SYSTEM

# In the chntpw shell:
cd HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\BTHPORT\Parameters\Keys
ls
cat <adapter_mac>\<device_mac>
```

---

## Tips

- After setting the key, run `bluetoothctl trust <MAC>` so Linux auto-connects.
- The NixOS config in configuration.nix enables `hardware.bluetooth.settings.General.FastConnectable = "true"` which speeds up reconnection after an OS switch.
- If using a BLE mouse/keyboard, you need to sync BOTH the LongTermKey AND the identity resolving key (IRK). Use the `bluetooth-fixer` script from the bt-dualboot AUR package as a reference.
