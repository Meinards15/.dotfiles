# VPN / Tor / Proxy Usage Guide

## Network Lanes Overview

| Lane | Description | How to use |
|------|-------------|------------|
| Clearnet | Direct ISP connection | Default — no config needed |
| System VPN | All host traffic via WireGuard | `nmcli connection up <name>` |
| Tor-over-VPN | Tor on top of active VPN | `torify <cmd>` or SOCKS5 :9050 |
| Per-app VPN | Container in its own WireGuard netns | `firefox-sandbox --vpn wg-app0` |

---

## 1. System-Wide VPN (WireGuard via NetworkManager)

### Setup
Create `/etc/NetworkManager/system-connections/wg0.nmconnection` (mode 0600):

```ini
[connection]
id=wg0
type=wireguard
autoconnect=false

[wireguard]
private-key=<YOUR_PRIVATE_KEY>

[wireguard-peer.<SERVER_PUBKEY>]
endpoint=<SERVER_IP>:51820
allowed-ips=0.0.0.0/0,::/0

[ipv4]
method=manual
address1=<TUNNEL_IP>/32
dns=<VPN_DNS>;
never-default=false

[ipv6]
method=disabled
```

### Usage
```bash
nmcli connection up wg0        # connect
nmcli connection down wg0      # disconnect
curl https://ifconfig.me       # verify exit IP
```

### Kill-switch
Uncomment the `extraInputRules` block in network.nix to block all traffic
if the VPN interface drops.

---

## 2. Tor-over-VPN

The Tor service starts automatically (enabled in network.nix).
Connect the system VPN first, then route apps through Tor.

```bash
# Route a single command through Tor
torify curl https://check.torproject.org/api/ip

# Use proxychains for apps that torify can't wrap
proxychains4 <application>

# Verify Tor is working
curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
```

Monitor Tor circuits:
```bash
nyx       # Tor monitor TUI (needs ControlPort=9051 — set in network.nix)
```

---

## 3. Per-App VPN (Container with dedicated WireGuard namespace)

Each sandboxed app can have its OWN VPN exit point, independent of the system.

### Setup (once per VPN endpoint)

1. Add a wg-quick interface in network.nix:
```nix
networking.wg-quick.interfaces.wg-app0 = {
    address    = [ "10.100.0.2/32" ];
    privateKey = "<CONTAINER_PRIVATE_KEY>";
    peers = [{
        publicKey  = "<SERVER_PUBLIC_KEY>";
        endpoint   = "<SERVER_IP>:51820";
        allowedIPs = [ "0.0.0.0/0" ];
    }];
};
```

2. Rebuild: `sudo nixos-rebuild switch --flake .`

### Usage

```bash
# Launch Firefox sandboxed through wg-app0
firefox-sandbox --vpn wg-app0

# Or through Tor (shares host net, routes via SOCKS5)
firefox-sandbox --tor
```

---

## 4. HTTP/SOCKS Proxy

To route a single app through a local proxy (e.g. Privoxy, mitmproxy):

```bash
# SOCKS5 (Tor)
curl --socks5-hostname 127.0.0.1:9050 https://example.com

# HTTP proxy
http_proxy=http://127.0.0.1:8118 curl https://example.com

# Global proxy for all apps in a shell session
export http_proxy=http://127.0.0.1:8118
export https_proxy=http://127.0.0.1:8118
export SOCKS_PROXY=socks5://127.0.0.1:9050
```

Uncomment the `environment.sessionVariables` block in network.nix to set
these globally.
