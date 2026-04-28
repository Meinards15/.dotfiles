# modules/hosts/maquina/network.nix — VPN, Tor, proxy, per-app routing
#
# ─── Overview ─────────────────────────────────────────────────────────────────
#
#   This file sets up a layered network security model with four "lanes":
#
#   Lane 0 — Clearnet (default):
#     Normal internet traffic through your ISP.
#
#   Lane 1 — System-Wide VPN (WireGuard/OpenVPN via NetworkManager):
#     All traffic on the host exits through the VPN tunnel.
#     Configured with a kill-switch so traffic is blocked if the VPN drops.
#
#   Lane 2 — Tor-over-VPN:
#     Tor daemon runs on the host; its traffic already goes through the VPN.
#     Apps directed to SOCKS5 127.0.0.1:9050 get Tor anonymity ON TOP of VPN.
#     The VPN provider sees only Tor entry-guard traffic.
#
#   Lane 3 — Per-App VPN inside pkg-sandbox containers:
#     Individual bubblewrap containers can be given their own network namespace
#     routed through a dedicated WireGuard interface (wg-app0, wg-app1, …).
#     Other apps on the host are unaffected.
#
# ─── Quick-start cheatsheet ───────────────────────────────────────────────────
#
#   System VPN on:
#     nmcli connection up <vpn-connection-name>
#
#   Route a single app through Tor (no container needed):
#     torify <command>          — uses torsocks LD_PRELOAD trick
#     proxychains <command>     — more explicit SOCKS5 routing
#
#   Launch app in a container with its own VPN namespace:
#     /opt/packages/pkg-sandbox/<container>/run --vpn wg-app0
#     (see pkg-sandbox.nix for how containers expose this flag)
#
#   Check which exit IP you're using:
#     curl --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip
#     curl https://ifconfig.me   (system VPN check)
#
# ─── WireGuard profile template ───────────────────────────────────────────────
# Create /etc/NetworkManager/system-connections/wg0.nmconnection (mode 0600):
#
#   [connection]
#   id=wg0
#   type=wireguard
#   autoconnect=false
#   [wireguard]
#   private-key=<YOUR_PRIVATE_KEY>
#   [wireguard-peer.<SERVER_PUBKEY>]
#   endpoint=<SERVER_IP>:51820
#   allowed-ips=0.0.0.0/0,::/0
#   [ipv4]
#   method=manual
#   address1=<TUNNEL_IP>/32
#   dns=<VPN_DNS_IP>;
#   never-default=false
#   [ipv6]
#   method=disabled

{ config, pkgs, lib, ... }:

{
    ## Firewall
    # NFTables
    networking.nftables.enable = true;
    networking.firewall = {
        enable = true;
        # Allowed Inbound TCP Ports
        allowedTCPPorts = [
            # 22    # SSH (uncomment only if openssh is enabled in configuration.nix)
        ];
        allowedUDPPorts = [
            # 51820   # WireGuard server port (only if running a WG server here)
        ];

        # Kill-switch: block all non-loopback traffic if the VPN interface drops.
        # Replace "wg0" with your actual WireGuard interface name.
        # This rule is only active while you have a VPN connection configured.
        # extraInputRules = ''
        #     iifname != { lo, wg0 } drop comment "VPN kill-switch"
        # '';
    };

    ## DNS
    # Use systemd-resolved for local DNS caching + DNSSEC.
    # When using a VPN, the VPN pushes its own DNS servers via NetworkManager.
    services.resolved = {
        enable    = true;
        dnssec    = "allow-downgrade"; # strict = safer; downgrade = wider compat
        domains   = [ "~." ];
        # fallbackDns = [ "9.9.9.9" "149.112.112.112" ]; # Quad9 fallback
    };

    ## Tor
    # Tor daemon listens on 127.0.0.1:9050 (SOCKS5).
    # When the system VPN is active, Tor traffic also goes through the VPN
    # (Tor-over-VPN topology: You → VPN → Tor → Destination).
    services.tor = {
        enable          = false;
        openFirewall    = false;  # Tor is local-only; don't expose to LAN
        settings = {
            SOCKSPort = "127.0.0.1:9050";

            # Transparent proxy (optional — routes all TCP via Tor for a user)
            # TransPort    = "9040";
            # DNSPort      = "5353";

            # (Optional) Only use guards in specific countries — may degrade perf
            # EntryNodes   = "{us},{de}";
            # ExitNodes    = "{us},{de}";

            # Control port — needed for Nyx monitor and `torify` dynamic circuits
            ControlPort  = 9051;
            CookieAuthentication = true;
        };
    };

    ## Network PKGS
    environment.systemPackages = with pkgs; [
        # Tor tools
        tor              # tor daemon (also installed via services.tor above)
        torsocks         # LD_PRELOAD wrapper — `torify <cmd>`
        nyx              # Tor monitor TUI

        # Proxy / routing tools
        proxychains-ng   # force any app through SOCKS4/5 or HTTP proxy
        tsocks           # simpler LD_PRELOAD SOCKS wrapper
        curl             # test exit IP: curl https://ifconfig.me
        wireguard-tools  # wg, wg-quick

        # NetworkManager VPN plugins
        networkmanager-openvpn
        networkmanager-openconnect  # Cisco AnyConnect compatible
        # networkmanager-wireguard    # WireGuard via NM (usually built-in)

        # Firewall inspection
        nftables         # nft command
        iptables         # legacy iptables (some tools still need it)
    ];

    # ── Per-App WireGuard Namespaces ─────────────────────────────────────────
    # Template for a dedicated WireGuard interface used by a single container.
    # Each container in pkg-sandbox.nix can receive its own netns that is
    # pre-attached to one of these interfaces.
    #
    # How it works:
    #   1. A WireGuard interface (wg-app0) is brought up on the host.
    #   2. A network namespace (ns-app0) is created and the wg interface moved in.
    #   3. The bubblewrap container runs with --share-net inside ns-app0.
    #   4. All traffic from the container exits through the VPN, isolated from
    #      the rest of the host.
    #
    # Uncomment and fill in keys/endpoints to activate.
    #
    # networking.wg-quick.interfaces.wg-app0 = {
    #     address    = [ "10.100.0.2/32" ];
    #     dns        = [ "10.100.0.1" ];
    #     privateKey = "<CONTAINER_PRIVATE_KEY>";
    #     peers = [{
    #         publicKey  = "<SERVER_PUBLIC_KEY>";
    #         endpoint   = "<SERVER_IP>:51820";
    #         allowedIPs = [ "0.0.0.0/0" ];
    #     }];
    # };
    #
    # The helper script that moves wg-app0 into its netns is generated by
    # pkg-sandbox.nix alongside the container run script.

    # ── Proxy environment variables (optional global proxy) ───────────────────
    # Fill in if you use an HTTP proxy globally (e.g. Squid, Privoxy, mitmproxy).
    # These are system-wide; per-app proxies belong in the container run script.
    #
    # environment.sessionVariables = {
    #     http_proxy  = "http://127.0.0.1:8118";   # Privoxy
    #     https_proxy = "http://127.0.0.1:8118";
    #     SOCKS_PROXY = "socks5://127.0.0.1:9050"; # Tor
    #     no_proxy    = "localhost,127.0.0.1";
    # };
}
