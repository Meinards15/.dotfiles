# modules/hosts/maquina/hardening.nix — kernel, polkit, AppArmor, audit, PAM
#
# ─── Hardening overview ───────────────────────────────────────────────────────
# Layer 1 — Kernel sysctl:     restrict ptrace, hide kptrs, protect ASLR, etc.
# Layer 2 — Module blacklist:  block rarely-needed network protocols
# Layer 3 — AppArmor:          MAC confinement for individual programs
# Layer 4 — Audit:             tamper-evident log of privilege escalations
# Layer 5 — PAM:               file-descriptor limit enforcement
# Layer 6 — doas / sudo:       minimal privilege escalation config
# Layer 7 — Firewall:          nftables (defined in network.nix)

{ config, pkgs, lib, ... }:

{
    # ── Privilege Escalation ─────────────────────────────────────────────────
    security.polkit.enable = true;

    # doas — leaner than sudo, preferred for interactive use
    security.doas = {
        enable     = true;
        extraRules = [{
            groups   = [ "wheel" ];
            keepEnv  = true;   # preserve environment (needed for nix commands)
            persist  = true;   # cache credentials briefly (like sudo -v)
            noPass   = false;  # always require password
        }];
    };

    # sudo kept for compatibility with scripts that hardcode it
    security.sudo = {
        enable            = true;
        wheelNeedsPassword = true;
        # Limit what wheel can do without a password if you want finer control:
        # extraRules = [{ ... }];
    };

    # ── PAM — Resource Limits ─────────────────────────────────────────────────
    # Raise open-file limits globally.  Many apps (databases, node) fail silently
    # if the default 1024 is hit.
    security.pam.loginLimits = [
        { domain = "*"; type = "soft"; item = "nofile"; value = "65536";  }
        { domain = "*"; type = "hard"; item = "nofile"; value = "524288"; }
    ];

    # ── Kernel Hardening (sysctl) ─────────────────────────────────────────────
    # Reference: https://kernel.org/doc/html/latest/admin-guide/sysctl/
    boot.kernel.sysctl = {

        # Memory layout
        "kernel.randomize_va_space" = 2;      # full ASLR (stack + heap + mmap)
        "kernel.kptr_restrict"      = 2;      # hide kernel pointer values in /proc

        # Process inspection
        # 1 = ptrace restricted to direct parent; 2 = admin-only; 3 = disabled
        "kernel.yama.ptrace_scope"  = 1;

        # SysRq — disable all magic keys (prevent local reset attacks)
        "kernel.sysrq" = 0;

        # Filesystem hardening
        "fs.protected_symlinks"  = 1;   # prevent TOCTOU via symlinks
        "fs.protected_hardlinks" = 1;   # prevent hardlink privilege escalation
        "fs.protected_fifos"     = 2;   # restrict FIFO creation in sticky dirs
        "fs.protected_regular"   = 2;   # restrict regular file creation in sticky dirs

        # Log access
        "kernel.dmesg_restrict" = 1;    # non-root cannot read dmesg

        # Network hardening
        "net.ipv4.conf.all.rp_filter"       = 1;   # reverse path filtering
        "net.ipv4.conf.default.rp_filter"   = 1;
        "net.ipv4.conf.all.accept_redirects"    = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects"    = 0;
        "net.ipv4.conf.all.send_redirects"      = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.tcp_syncookies"               = 1;  # SYN flood mitigation
        "net.ipv4.tcp_rfc1337"                  = 1;  # TIME_WAIT assassination
        "net.core.bpf_jit_harden"              = 2;  # harden BPF JIT against info leaks
    };

    # ── Kernel Module Blacklist ───────────────────────────────────────────────
    # These protocols are rarely needed on a desktop and have had CVEs.
    boot.blacklistedKernelModules = [
        "dccp"    # Datagram Congestion Control Protocol
        "sctp"    # Stream Control Transmission Protocol
        "rds"     # Reliable Datagram Sockets
        "tipc"    # Transparent Inter-Process Communication
        "n-hdlc"  # HDLC line discipline
        "ax25"    # Amateur radio
        "netrom"  # Amateur packet radio
        "x25"     # X.25 protocol
        "rose"    # Rose protocol
        "decnet"  # DECnet
        "econet"  # Acorn Econet
        "af_802154" # IEEE 802.15.4
        "ipx"     # IPX/SPX
        "appletalk"
        "psnap"
        "p8023"
        "llc"
        "p8022"
    ];

    # ── AppArmor (Mandatory Access Control) ──────────────────────────────────
    security.apparmor = {
        enable = true;
        # killUnconfinedConfinables = true;  # uncomment to enforce strictly
    };

    # ── Audit Subsystem ───────────────────────────────────────────────────────
    # Logs are at /var/log/audit/audit.log (on the @log subvolume)
    security.audit.enable  = true;
    security.auditd.enable = true;
    security.audit.rules = [
        # Track privilege escalation binaries
        "-w /run/current-system/sw/bin/sudo -p x -k priv_esc"
        "-w /run/current-system/sw/bin/doas -p x -k priv_esc"

        # Track modifications to /etc (config drift detection)
        "-w /etc -p wa -k etc_changes"

        # Track writes to /opt/packages/pkg-sandbox (container tampering)
        "-w /opt/packages/pkg-sandbox -p wa -k sandbox_changes"

        # Track writes to sudoers / doas.conf
        "-w /etc/doas.conf -p wa -k priv_esc_config"
    ];

    # ── USBGuard (optional — uncomment to whitelist USB devices) ─────────────
    # services.usbguard = {
    #     enable    = true;
    #     # Generate initial policy: `usbguard generate-policy > /etc/usbguard/rules.conf`
    #     rules     = builtins.readFile ./usbguard-rules.conf;
    # };
}
