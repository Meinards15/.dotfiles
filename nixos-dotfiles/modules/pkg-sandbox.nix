# modules/hosts/maquina/pkg-sandbox.nix — bubblewrap application sandboxing
#
# ─── Purpose ──────────────────────────────────────────────────────────────────
# Each app runs in an isolated Linux namespace (bubblewrap / bwrap).
# No network by default (--unshare-all covers it). No capabilities. No home
# unless explicitly granted via a profile flag.
#
# ─── Access model ─────────────────────────────────────────────────────────────
#   isolpkg  — full control over /opt/packages/pkg-sandbox  (mode 0770, group isolpkg)
#   syspkg   — full control over /opt/packages/* EXCEPT pkg-sandbox
#   sandbox  — identity used by processes INSIDE a container (never a login shell)
#
# ─── Profiles ─────────────────────────────────────────────────────────────────
# --unshare-all in baseFlags already gives no-network isolation.
# flagFullNet (--share-net) re-grants host networking where needed.
# flagNoNet is therefore NOT needed — omitting flagFullNet means no network.
#
# Available flags (combine freely):
#   flagFullNet      — host network namespace (browsers, chat)
#   flagDisplay      — Wayland socket                (GUI apps)
#   flagGPU          — /dev/dri + sysfs              (GPU rendering)
#   flagAudio        — PipeWire / Pulse sockets       (media)
#   flagDBus         — filtered session D-Bus         (portals, notifications)
#   flagHomeRO       — read-only /home
#   flagHomeRW       — read-write /home
#   flagDownloads    — rw ~/Downloads only
#   flagDocumentsRO  — ro ~/Documents only
#   flagKeePassXC    — KeePassXC browser socket
#
# ─── VPN / Tor per container ──────────────────────────────────────────────────
#   firefox-sandbox --vpn wg-app0    dedicated WireGuard netns
#   firefox-sandbox --tor            SOCKS5 via host Tor daemon (network.nix)

{ config, pkgs, lib, ... }:

let
    user        = "thadfake";
    sandboxBase = "/opt/packages/pkg-sandbox";
    bwrap       = "${pkgs.bubblewrap}/bin/bwrap";

    # ── Base flags (every sandbox) ────────────────────────────────────────────
    # --unshare-all isolates user+ipc+pid+net+uts+cgroup namespaces.
    # Per-profile flags selectively re-add what the app needs (--share-net etc).
    baseFlags = [
        "--ro-bind /nix                        /nix"
        "--ro-bind /run/current-system         /run/current-system"
        "--ro-bind /run/booted-system          /run/booted-system"
        "--ro-bind /run/current-system/sw/bin  /run/current-system/sw/bin"
        "--ro-bind /etc/fonts                  /etc/fonts"
        "--ro-bind /etc/ssl                    /etc/ssl"
        "--ro-bind /etc/resolv.conf            /etc/resolv.conf"
        "--ro-bind /etc/hosts                  /etc/hosts"
        "--ro-bind /etc/locale.conf            /etc/locale.conf"
        "--tmpfs   /tmp"
        "--tmpfs   /home"
        "--proc    /proc"
        "--dev     /dev"
        "--dev-bind /dev/null    /dev/null"
        "--dev-bind /dev/zero    /dev/zero"
        "--dev-bind /dev/random  /dev/random"
        "--dev-bind /dev/urandom /dev/urandom"
        "--dev-bind /dev/tty     /dev/tty"
        "--unshare-all"      # isolates all namespaces; profiles re-add selectively
        "--die-with-parent"  # kill sandbox when launcher dies
        "--cap-drop ALL"     # drop all capabilities
        # --new-session intentionally omitted from base: breaks CLI terminal control.
        # Add it per-profile for GUI-only apps where no tty is needed.
    ];

    ## Profile flag sets

    # Full network: re-adds host net namespace (overrides --unshare-all for net)
    flagFullNet = [ "--share-net" ];

    # Wayland socket (vars expanded at runtime inside the generated shell script)
    flagDisplay = [
        "--ro-bind-try \${XDG_RUNTIME_DIR}/\${WAYLAND_DISPLAY} \${XDG_RUNTIME_DIR}/\${WAYLAND_DISPLAY}"
        "--setenv XDG_RUNTIME_DIR \${XDG_RUNTIME_DIR}"
        "--setenv WAYLAND_DISPLAY \${WAYLAND_DISPLAY}"
        "--setenv DISPLAY :0"
    ];

    # GPU / DRI access
    flagGPU = [
        "--dev-bind-try /dev/dri      /dev/dri"
        "--ro-bind-try  /sys/dev/char /sys/dev/char"
        "--ro-bind-try  /sys/devices  /sys/devices"
        "--ro-bind-try  /sys/bus/pci  /sys/bus/pci"
    ];

    # Audio: PipeWire + PulseAudio compat sockets (ro — process only reads them)
    flagAudio = [
        "--ro-bind-try \${XDG_RUNTIME_DIR}/pipewire-0 \${XDG_RUNTIME_DIR}/pipewire-0"
        "--ro-bind-try \${XDG_RUNTIME_DIR}/pulse      \${XDG_RUNTIME_DIR}/pulse"
    ];

    # D-Bus: filtered via xdg-dbus-proxy started in the run script.
    # Must be --bind-try (rw) — the proxy socket is a Unix domain socket that
    # the sandboxed process connects to (needs write access to send messages).
    flagDBus = [
        "--bind-try \${XDG_RUNTIME_DIR}/bus-proxy-\${APP_NAME} \${XDG_RUNTIME_DIR}/bus"
        "--setenv DBUS_SESSION_BUS_ADDRESS unix:path=\${XDG_RUNTIME_DIR}/bus"
    ];

    flagHomeRO      = [ "--ro-bind /home/${user} /home/${user}" ];
    flagHomeRW      = [ "--bind    /home/${user} /home/${user}" ];
    flagDownloads   = [ "--bind    /home/${user}/Downloads  /home/${user}/Downloads" ];
    flagDocumentsRO = [ "--ro-bind /home/${user}/Documents  /home/${user}/Documents" ];

    # KeePassXC browser integration: binds config dir and runtime socket rw
    flagKeePassXC = [
        "--bind-try \${HOME}/.config/keepassxc              \${HOME}/.config/keepassxc"
        "--bind-try /run/user/\${UID}/kpxc_server  /run/user/\${UID}/kpxc_server"
    ];

    ## Profile compositions
    # --new-session added to GUI profiles to prevent terminal ptrace attacks.
    # Omit for dev/CLI profiles that need a controlling terminal.

    profileGUI    = flagDisplay ++ flagGPU ++ flagDBus ++ flagDocumentsRO
                    ++ [ "--new-session" ];

    profileMedia  = flagDisplay ++ flagGPU ++ flagAudio ++ flagDBus ++ flagHomeRO
                    ++ [ "--new-session" ];

    profileEditor = flagDisplay ++ flagGPU ++ flagDBus ++ flagHomeRW
                    ++ [ "--new-session" ];

    profileBrowser = flagFullNet ++ flagDisplay ++ flagGPU ++ flagAudio
                     ++ flagDBus ++ flagDownloads ++ flagKeePassXC
                     ++ [ "--new-session" ];

    profileMessaging = flagFullNet ++ flagDisplay ++ flagGPU ++ flagAudio
                       ++ flagDBus ++ flagDownloads ++ [ "--new-session"
                           "--bind /home/${user}/.config/signal /home/${user}/.config/signal" ];

    # Dev: no --new-session (needs terminal control), no network by default
    profileDev = flagDisplay ++ flagGPU ++ flagDBus ++ flagHomeRW;

    ## Script generator
    # mkContainer { name, exec, profileFlags, extraBinds?, categories?, mimeTypes? }
    mkContainer = { name, exec, profileFlags, extraBinds ? [],
                    categories ? "Application", mimeTypes ? "" }:
    let
        allFlags = baseFlags ++ profileFlags ++ extraBinds;
        flagStr  = lib.concatStringsSep " \\\n            " allFlags;
    in
    pkgs.writeShellScriptBin name ''
        #!/usr/bin/env bash
        # ${name} — sandboxed launcher (generated by pkg-sandbox.nix)
        #
        # Usage: ${name} [--vpn <wg-iface>] [--tor] [--] [app args…]
        #   --vpn <iface>  run inside dedicated WireGuard network namespace
        #   --tor          route through host Tor SOCKS5 (services.tor in network.nix)
        set -euo pipefail

        APP_NAME="${name}"
        CONTAINER_HOME="${sandboxBase}/${name}/home"
        VPN_IFACE=""
        USE_TOR=0

        ## Parse flags
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --vpn) VPN_IFACE="$2"; shift 2 ;;
                --tor) USE_TOR=1;       shift   ;;
                --)    shift; break ;;
                *)     break ;;
            esac
        done

        ## D-Bus proxy — start filtered proxy before launching bwrap
        DBUS_PROXY_SOCK="''${XDG_RUNTIME_DIR}/bus-proxy-''${APP_NAME}"
        DBUS_PROXY_PID=""
        if [[ -S "''${XDG_RUNTIME_DIR}/bus" ]]; then
            ${pkgs.xdg-dbus-proxy}/bin/xdg-dbus-proxy \
                "''${DBUS_SESSION_BUS_ADDRESS:-unix:path=''${XDG_RUNTIME_DIR}/bus}" \
                "''${DBUS_PROXY_SOCK}" \
                --filter \
                --call="org.freedesktop.portal.*=*" \
                --talk="org.freedesktop.Notifications" &
            DBUS_PROXY_PID=$!
            sleep 0.1
        fi

        ## VPN network namespace
        NETNS_EXEC=()
        if [[ -n "$VPN_IFACE" ]]; then
            NETNS="ns-''${APP_NAME}"
            if ! ip netns list | grep -q "^''${NETNS}[[:space:]]"; then
                ip netns add "''${NETNS}"
                ip link set "''${VPN_IFACE}" netns "''${NETNS}"
                ip -n "''${NETNS}" link set lo up
                ip -n "''${NETNS}" link set "''${VPN_IFACE}" up
            fi
            NETNS_EXEC=( ip netns exec "''${NETNS}" )
        fi

        ## Tor env — bash array avoids word-splitting on multi-word string
        TOR_ENV=()
        if [[ "$USE_TOR" -eq 1 ]]; then
            TOR_ENV=(
                env
                SOCKS5_SERVER=127.0.0.1:9050
                SOCKS_SERVER=127.0.0.1:9050
                http_proxy=socks5h://127.0.0.1:9050
                https_proxy=socks5h://127.0.0.1:9050
            )
        fi

        ## Launch
        "''${NETNS_EXEC[@]}" "''${TOR_ENV[@]}" ${bwrap} \
            ${flagStr} \
            --bind "''${CONTAINER_HOME}" "/home/${user}" \
            -- ${exec} "$@"
        EXIT_CODE=$?

        ## Cleanup
        [[ -n "''${DBUS_PROXY_PID}" ]] && kill "''${DBUS_PROXY_PID}" 2>/dev/null || true
        exit $EXIT_CODE
    '';

in

{
    ## Runtime dependencies
    environment.systemPackages = with pkgs; [
        bubblewrap
        xdg-dbus-proxy
        libseccomp
        torsocks

        ## Sandboxed app wrappers

        # Firefox — browser (network, GPU, audio, Downloads, KeePassXC)
        (mkContainer {
            name         = "firefox-sandbox";
            exec         = "${pkgs.firefox}/bin/firefox";
            profileFlags = profileBrowser;
            extraBinds   = [
                "--bind /home/${user}/.mozilla /home/${user}/.mozilla"
            ];
            categories   = "Network;WebBrowser;";
            mimeTypes    = "text/html;x-scheme-handler/http;x-scheme-handler/https;";
        })

        # mpv — media player (local files, audio, GPU, no network)
        (mkContainer {
            name         = "mpv-sandbox";
            exec         = "${pkgs.mpv}/bin/mpv";
            profileFlags = profileMedia;
            categories   = "Video;AudioVideo;";
            mimeTypes    = "video/mp4;video/x-matroska;audio/mpeg;audio/flac;audio/ogg;";
        })

        # zathura — PDF viewer (Documents ro, no network)
        (mkContainer {
            name         = "zathura-sandbox";
            exec         = "${pkgs.zathura}/bin/zathura";
            profileFlags = profileGUI;
            categories   = "Office;Viewer;";
            mimeTypes    = "application/pdf;";
        })

        # ── Add containers below — copy a block and adjust ────────────────────
        # (mkContainer {
        #     name         = "signal-sandbox";
        #     exec         = "${pkgs.signal-desktop}/bin/signal-desktop";
        #     profileFlags = profileMessaging;
        #     categories   = "Network;InstantMessaging;";
        # })
    ];

    ## Container directory scaffolding
    systemd.tmpfiles.rules = [
        "d ${sandboxBase}/firefox-sandbox        0770 ${user} isolpkg -"
        "d ${sandboxBase}/firefox-sandbox/rootfs 0770 ${user} isolpkg -"
        "d ${sandboxBase}/firefox-sandbox/home   0770 ${user} sandbox -"

        "d ${sandboxBase}/mpv-sandbox            0770 ${user} isolpkg -"
        "d ${sandboxBase}/mpv-sandbox/rootfs     0770 ${user} isolpkg -"
        "d ${sandboxBase}/mpv-sandbox/home       0770 ${user} sandbox -"

        "d ${sandboxBase}/zathura-sandbox        0770 ${user} isolpkg -"
        "d ${sandboxBase}/zathura-sandbox/rootfs 0770 ${user} isolpkg -"
        "d ${sandboxBase}/zathura-sandbox/home   0770 ${user} sandbox -"
    ];

    ## MIME defaults
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

    ## Desktop entries
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
