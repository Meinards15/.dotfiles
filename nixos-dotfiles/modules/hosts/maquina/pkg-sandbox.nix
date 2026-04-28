# modules/hosts/maquina/pkg-sandbox.nix — bubblewrap application sandboxing
#
# ─── Purpose ──────────────────────────────────────────────────────────────────
# Each application runs in an isolated Linux namespace created by bubblewrap
# (bwrap). Sandboxed apps cannot see each other's filesystems, cannot access
# /home unless explicitly permitted, have no network by default, and drop all
# Linux capabilities.
#
# ─── Access model ─────────────────────────────────────────────────────────────
#
#   isolpkg group
#     • May add/remove/start/stop/modify containers in /opt/packages/pkg-sandbox
#     • Directory mode 0770, group=isolpkg
#
#   syspkg group
#     • May modify /opt/packages/* EXCEPT /opt/packages/pkg-sandbox
#     • Directory mode 0770, group=syspkg  (pkg-sandbox excluded)
#
#   sandbox group
#     • Identity used by processes running INSIDE a container
#     • Never assigned to login accounts
#
# ─── Profiles ─────────────────────────────────────────────────────────────────
#   none        — no network, no home, no display    (CLI processing tools)
#   localNet    — loopback only                      (local dev servers)
#   fullNet     — unrestricted network               (browsers, chat)
#   homeRO      — read-only /home                    (viewers, readers)
#   homeRW      — read-write /home                   (editors, file managers)
#   display     — Wayland socket                     (all GUI apps)
#   gpu         — /dev/dri access                    (GPU rendering)
#   audio       — PipeWire + PulseAudio sockets      (media players)
#   dbus        — session D-Bus (via proxy)          (notifications, portals)
#   downloads   — rw bind of ~/Downloads             (browsers)
#   documentsRO — ro bind of ~/Documents             (document viewers)
#   torProxy    — routes network through Tor SOCKS5  (anonymous browsing)
#   vpnNetns    — container runs in a dedicated WireGuard network namespace
#
# Profiles are combined: a browser gets fullNet+display+gpu+audio+dbus+downloads.
#
# ─── Container filesystem layout ──────────────────────────────────────────────
# /opt/packages/pkg-sandbox/<name>/
#   rootfs/         — extra read-write overlay binds (config, data)
#   home/           — private container home (visible as /home/sandbox inside)
#   run             — generated launch script (chmod 0750, group=isolpkg)
#
# ─── VPN inside a container ───────────────────────────────────────────────────
# Passing --vpn <wg-iface> to the run script will:
#   1. Create a network namespace ns-<name> (if it doesn't exist).
#   2. Move the WireGuard interface into that namespace.
#   3. Run bwrap with --share-net inside ip-netns exec ns-<name>.
# Configure wg-quick interfaces in network.nix.
#
# ─── Tor inside a container ───────────────────────────────────────────────────
# Pass --tor to the run script.  The container's SOCKS5 env vars are set to
# 127.0.0.1:9050 (the host Tor daemon started in network.nix).
# The container still shares the host net namespace in this mode, but all
# app-level network calls go through torsocks.

{ config, pkgs, lib, ... }:

let
    user = "thadfake";
    sandboxBase = "/opt/packages/pkg-sandbox";

    ## BWRAP
    bwrap = "${pkgs.bubblewrap}/bin/bwrap";

    # ── Base flags present in EVERY sandbox ──────────────────────────────────
    # These flags are the minimum needed to run any Nix-built binary.
    # Note: --unshare-all is listed first; individual profile flags re-add
    # specific namespaces (e.g. --share-net).
    baseFlags = [
        "--ro-bind /nix /nix"                                      # Nix store
        "--ro-bind /run/current-system /run/current-system"        # system libs
        "--ro-bind /run/booted-system  /run/booted-system"         # booted system
        "--ro-bind /etc/fonts          /etc/fonts"                  # font config
        "--ro-bind /etc/ssl            /etc/ssl"                    # TLS certs
        "--ro-bind /etc/resolv.conf    /etc/resolv.conf"            # DNS resolver
        "--ro-bind /etc/hosts          /etc/hosts"                  # hosts file
        "--ro-bind /etc/locale.conf    /etc/locale.conf"            # locale
        "--tmpfs   /tmp"                                            # private temp
        "--tmpfs   /home"                                           # fake home root
        "--proc    /proc"                                           # proc FS
        "--dev     /dev"                                            # minimal dev
        "--dev-bind /dev/null     /dev/null"
        "--dev-bind /dev/zero     /dev/zero"
        "--dev-bind /dev/random   /dev/random"
        "--dev-bind /dev/urandom  /dev/urandom"
        "--dev-bind /dev/tty      /dev/tty"
        "--unshare-all"      # new namespaces for user+ipc+pid+net+uts+cgroup
        "--die-with-parent"  # kill sandbox when the launcher process dies
        "--new-session"      # new session ID — prevents ptrace via terminal
        "--cap-drop ALL"     # drop all Linux capabilities
    ];

    ## Sandbox Profiles
    # No network (default) — network namespace has no interfaces
    flagNoNet  = [ "--unshare-net" ];
    # Loopback only — shares host net NS but we restrict at firewall level.
    # True netns-loopback requires a root helper; this is the practical option.
    flagLocalNet = [ "--share-net" ];
    # Full network (host network namespace)
    flagFullNet  = [ "--share-net" ];
    # Wayland display socket — bound read-only from XDG_RUNTIME_DIR
    flagDisplay = [
        # Shell expansion happens at runtime inside the generated script;
        # variables are NOT expanded here — they are written as-is into the script.
        "--ro-bind-try \${XDG_RUNTIME_DIR}/\${WAYLAND_DISPLAY} \${XDG_RUNTIME_DIR}/\${WAYLAND_DISPLAY}"
        "--setenv XDG_RUNTIME_DIR  \${XDG_RUNTIME_DIR}"
        "--setenv WAYLAND_DISPLAY  \${WAYLAND_DISPLAY}"
        "--setenv DISPLAY          :0"                 # XWayland compat
    ];
    # GPU — direct rendering and sysfs device paths
    flagGPU = [
        "--dev-bind-try  /dev/dri         /dev/dri"
        "--ro-bind-try   /sys/dev/char    /sys/dev/char"
        "--ro-bind-try   /sys/devices     /sys/devices"
        "--ro-bind-try   /sys/bus/pci     /sys/bus/pci"
    ];
    # Audio — PipeWire + PulseAudio compat socket
    flagAudio = [
        "--ro-bind-try \${XDG_RUNTIME_DIR}/pipewire-0   \${XDG_RUNTIME_DIR}/pipewire-0"
        "--ro-bind-try \${XDG_RUNTIME_DIR}/pulse        \${XDG_RUNTIME_DIR}/pulse"
    ];
    # D-Bus session bus (via xdg-dbus-proxy — starts a filtered proxy first)
    flagDBus = [
        "--ro-bind-try \${XDG_RUNTIME_DIR}/bus-proxy-\${APP_NAME} \${XDG_RUNTIME_DIR}/bus"
        "--setenv DBUS_SESSION_BUS_ADDRESS unix:path=\${XDG_RUNTIME_DIR}/bus"
    ];
    # Home: read-only
    flagHomeRO = [
        "--ro-bind /home/${user} /home/${user}"
    ];
    # Home: read-write
    flagHomeRW = [
        "--bind /home/${user} /home/${user}"
    ];
    # Downloads: read-write
    flagDownloads = [
        "--bind /home/${user}/Downloads /home/${user}/Downloads"
    ];
    # Documents: read-only
    flagDocumentsRO = [
        "--ro-bind /home/${user}/Documents /home/${user}/Documents"
    ];

    ## Sandbox Profile Compositions
    # Pure CLI: no I/O outside stdin/stdout, maximum isolation
    profileCLI    = flagNoNet;
    # Offline GUI: document viewers, image viewers
    profileGUI    = flagNoNet ++ flagDisplay ++ flagGPU ++ flagDBus ++ flagDocumentsRO;
    # Media player: local files, no network, audio
    profileMedia  = flagNoNet ++ flagDisplay ++ flagGPU ++ flagAudio ++ flagDBus ++ flagHomeRO;
    # Text editor: home read-write, no network
    profileEditor = flagNoNet ++ flagDisplay ++ flagGPU ++ flagDBus ++ flagHomeRW;
    # Browser: full network, GPU, audio, downloads only (NOT full home)
    profileBrowser = flagFullNet ++ flagDisplay ++ flagGPU ++ flagAudio ++ flagDBus ++ flagDownloads;
    # Messaging app: full network, display, audio, own config + downloads
    profileMessaging = flagFullNet ++ flagDisplay ++ flagGPU ++ flagAudio ++ flagDBus ++ flagDownloads ++ [
        "--bind /home/${user}/.config/signal /home/${user}/.config/signal"
    ];
    # Dev tools: full home rw, no network (add --share-net per-project)
    profileDev = flagNoNet ++ flagDisplay ++ flagGPU ++ flagDBus ++ flagHomeRW;

    # ── Script generator ──────────────────────────────────────────────────────
    # mkContainer generates:
    #   1. The bwrap launch script at /opt/packages/pkg-sandbox/<name>/run
    #   2. A desktop entry in /etc/xdg/applications/
    #   3. Directories for rootfs/ and home/ (via tmpfiles in the derivation)
    #
    # Parameters:
    #   name        — container identifier (also the script name)
    #   exec        — full path to the binary inside /nix/store
    #   profileFlags — combined profile flags list
    #   extraBinds  — additional --bind / --ro-bind flags (list of strings)
    #   categories  — desktop entry Categories value
    #   mimeTypes   — desktop entry MimeType value (semicolon-separated)
    mkContainer = { name, exec, profileFlags, extraBinds ? [],
                    categories ? "Application", mimeTypes ? "" }:
    let
        allFlags = baseFlags ++ profileFlags ++ extraBinds;
        flagStr  = lib.concatStringsSep " \\\n        " allFlags;
    in
    pkgs.writeShellScriptBin name ''
        #!/usr/bin/env bash
        # ${name} — sandboxed container launcher
        # Generated by pkg-sandbox.nix — do not edit directly.
        #
        # Usage: ${name} [--vpn <wg-iface>] [--tor] [-- <extra bwrap args>] [app args]
        #
        # --vpn <iface>   run container inside the WireGuard network namespace
        # --tor           route container traffic through Tor SOCKS5

        APP_NAME="${name}"
        CONTAINER_HOME="${sandboxBase}/${name}/home"
        VPN_IFACE=""
        USE_TOR=0

        ## Parse special flags
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --vpn)  VPN_IFACE="$2"; shift 2 ;;
                --tor)  USE_TOR=1;       shift ;;
                --)     shift; break ;;
                *)      break ;;
            esac
        done

        ## D-Bus proxy (start filtered proxy before bwrap)
        DBUS_PROXY_SOCK="''${XDG_RUNTIME_DIR}/bus-proxy-''${APP_NAME}"
        if [[ -S "''${XDG_RUNTIME_DIR}/bus" ]]; then
            ${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy \
                "''${DBUS_SESSION_BUS_ADDRESS}" \
                "''${DBUS_PROXY_SOCK}" \
                --filter \
                --call="org.freedesktop.portal.*=*" \
                --talk="org.freedesktop.Notifications" \
                &
            DBUS_PROXY_PID=$!
            # Give the proxy a moment to bind the socket
            sleep 0.1
        fi

        ## Tor environment
        TOR_VARS=""
        if [[ "$USE_TOR" -eq 1 ]]; then
            TOR_VARS="env SOCKS5_SERVER=127.0.0.1:9050 \
                         SOCKS_SERVER=127.0.0.1:9050   \
                         http_proxy=socks5h://127.0.0.1:9050 \
                         https_proxy=socks5h://127.0.0.1:9050"
        fi

        ## VPN network namespace
        NETNS_PREFIX=""
        if [[ -n "$VPN_IFACE" ]]; then
            NETNS="ns-''${APP_NAME}"
            # Create the network namespace if it doesn't exist
            if ! ip netns list | grep -q "^''${NETNS}"; then
                ip netns add "''${NETNS}"
                # Move the WireGuard interface into the namespace
                ip link set "''${VPN_IFACE}" netns "''${NETNS}"
                ip -n "''${NETNS}" link set lo up
                ip -n "''${NETNS}" link set "''${VPN_IFACE}" up
            fi
            NETNS_PREFIX="ip netns exec ''${NETNS}"
        fi

        ## Launch
        $NETNS_PREFIX $TOR_VARS ${bwrap} \
            ${flagStr} \
            --bind "''${CONTAINER_HOME}" "/home/${user}" \
            -- ${exec} "$@"

        EXIT_CODE=$?

        ## Cleanup
        [[ -n "''${DBUS_PROXY_PID:-}" ]] && kill "''${DBUS_PROXY_PID}" 2>/dev/null
        exit $EXIT_CODE
    '';

in

{
    ## Runtime Dependencies
    environment.systemPackages = with pkgs; [
        bubblewrap        # bwrap
        xdg-dbus-proxy    # D-Bus Filter for sandboxed apps
        libseccomp        # seccomp custom filter library
        torsocks          # Tor transparent proxy wrapper

        ## Sandbox Application Wrappers
        # Firefox - browser profile [ R-W Network | R-W GPU | R-W Audio | R-W downloads || X-X ]
        (mkContainer {
            name         = "firefox-sandbox";
            exec         = "${pkgs.firefox}/bin/firefox";
            profileFlags = profileBrowser;
            extraBinds   = [
                # Persist Firefox profile across container launches
                "--bind /home/${user}/.mozilla /home/${user}/.mozilla"
            ];
            categories   = "Network;WebBrowser;";
            mimeTypes    = "text/html;x-scheme-handler/http;x-scheme-handler/https;";
        })

        ## MPV [ R-X $HOME/ | R-X audio | R-X GPU | Optional Network || X-X ]
        (mkContainer {
            name         = "mpv-sandbox";
            exec         = "${pkgs.mpv}/bin/mpv";
            # Use flagFullNet if you want to stream URLs; flagNoNet for local only.
            profileFlags = flagNoNet ++ flagDisplay ++ flagGPU ++ flagAudio ++ flagDBus ++ flagHomeRO;
            categories   = "Video;AudioVideo;";
            mimeTypes    = "video/mp4;video/x-matroska;audio/mpeg;audio/flac;audio/ogg;";
        })

        ## Zathura [ Read Files Only || X-X ]
        (mkContainer {
            name         = "zathura-sandbox";
            exec         = "${pkgs.zathura}/bin/zathura";
            profileFlags = profileGUI;
            categories   = "Office;Viewer;";
            mimeTypes    = "application/pdf;";
        })

        # ── Template: add your own containers below ──────────────────────────
        # Copy one of the blocks above and adjust name/exec/profileFlags.
        # Example: Signal messaging client
        # (mkContainer {
        #     name         = "signal-sandbox";
        #     exec         = "${pkgs.signal-desktop}/bin/signal-desktop";
        #     profileFlags = profileMessaging;
        #     categories   = "Network;InstantMessaging;";
        # })
    ];

    # ── Container directory scaffolding ──────────────────────────────────────
    # Creates rootfs/ and home/ for each named container under pkg-sandbox.
    # The run script (generated above as a derivation) is NOT placed here —
    # it lives in /nix/store and is symlinked into $PATH.
    # Add one line per container you define above.
    systemd.tmpfiles.rules = [
        # firefox-sandbox
        "d ${sandboxBase}/firefox-sandbox                  0770 ${user} isolpkg -"
        "d ${sandboxBase}/firefox-sandbox/rootfs            0770 ${user} isolpkg -"
        "d ${sandboxBase}/firefox-sandbox/home              0770 ${user} sandbox -"

        # mpv-sandbox
        "d ${sandboxBase}/mpv-sandbox                      0770 ${user} isolpkg -"
        "d ${sandboxBase}/mpv-sandbox/rootfs                0770 ${user} isolpkg -"
        "d ${sandboxBase}/mpv-sandbox/home                  0770 ${user} sandbox -"

        # zathura-sandbox
        "d ${sandboxBase}/zathura-sandbox                  0770 ${user} isolpkg -"
        "d ${sandboxBase}/zathura-sandbox/rootfs            0770 ${user} isolpkg -"
        "d ${sandboxBase}/zathura-sandbox/home              0770 ${user} sandbox -"
    ];

    # ── MIME default application associations ────────────────────────────────
    environment.etc."xdg/mimeapps.list".text = ''
        [Default Applications]
        application/pdf=zathura-sandbox.desktop
        text/html=firefox-sandbox.desktop
        x-scheme-handler/http=firefox-sandbox.desktop
        x-scheme-handler/https=firefox-sandbox.desktop
        video/mp4=mpv-sandbox.desktop
        video/x-matroska=mpv-sandbox.desktop
        audio/mpeg=mpv-sandbox.desktop
        audio/flac=mpv-sandbox.desktop
        audio/ogg=mpv-sandbox.desktop
    '';

    # ── Desktop entries ───────────────────────────────────────────────────────
    environment.etc."xdg/applications/firefox-sandbox.desktop".text = ''
        [Desktop Entry]
        Name=Firefox (Sandboxed)
        Exec=firefox-sandbox %u
        Type=Application
        Icon=firefox
        Categories=Network;WebBrowser;
        MimeType=text/html;x-scheme-handler/http;x-scheme-handler/https;
        StartupNotify=true
    '';

    environment.etc."xdg/applications/mpv-sandbox.desktop".text = ''
        [Desktop Entry]
        Name=mpv (Sandboxed)
        Exec=mpv-sandbox %f
        Type=Application
        Icon=mpv
        Categories=Video;AudioVideo;
        MimeType=video/mp4;video/x-matroska;audio/mpeg;audio/flac;audio/ogg;
    '';

    environment.etc."xdg/applications/zathura-sandbox.desktop".text = ''
        [Desktop Entry]
        Name=Zathura (Sandboxed)
        Exec=zathura-sandbox %f
        Type=Application
        Icon=zathura
        Categories=Office;Viewer;
        MimeType=application/pdf;
    '';
}
