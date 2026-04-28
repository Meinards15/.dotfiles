# modules/hosts/maquina/snapshots.nix — btrfs snapshots with snapper + btrbk
#
# ─── Snapshot topology ────────────────────────────────────────────────────────
#
#   snapper   — timeline (hourly/daily/weekly) + pre/post around rebuilds
#   btrbk     — sends snapshots to external drives or remote hosts (backup)
#
#   Snapshot storage locations:
#     Root snapshots  → /.snapshots/      (mapped to @snapshots btrfs subvol)
#     Home snapshots  → /home/.snapshots/ (snapper creates inside @home)
#     Pkgs snapshots  → /opt/packages/.snapshots/ (protect @pkgs state)
#
# ─── Restoring a snapshot ─────────────────────────────────────────────────────
#   List:     snapper -c root list
#   Diff:     snapper -c root diff 5..6
#   Restore:  snapper -c root undochange 5..0
#   Browse:   btrfs-assistant       (GUI)
#
# ─── Pre/post rebuild usage ───────────────────────────────────────────────────
#   rebuild-snap switch       (defined as a shell alias below)

{ config, pkgs, lib, ... }:

{
    ## PKGS
    environment.systemPackages = with pkgs; [
        snapper          # core snapshot CLI
        btrfs-assistant  # GUI to browse / restore snapshots
        btrbk            # snapshot backup to external drives
        compsize         # show actual compressed size of a btrfs path
        btrfs-progs      # btrfs command-line tools (mkfs, check, scrub…)
    ];

    # ── snapper: root (/) ─────────────────────────────────────────────────────
    services.snapper.configs.root = {
        SUBVOLUME    = "/";
        ALLOW_GROUPS = [ "wheel" ];
        ALLOW_USERS  = [];
        # Timeline schedule — hourly snapshots, cleaned by aging algorithm
        TIMELINE_CREATE  = "yes";
        TIMELINE_CLEANUP = "yes";
        # Retention: keep 10 hourly, 7 daily, 4 weekly, 6 monthly, 2 yearly
        TIMELINE_LIMIT_HOURLY  = "10";
        TIMELINE_LIMIT_DAILY   = "7";
        TIMELINE_LIMIT_WEEKLY  = "4";
        TIMELINE_LIMIT_MONTHLY = "6";
        TIMELINE_LIMIT_YEARLY  = "2";
        # Safety: stop creating snapshots if less than 20 % disk space remains
        SPACE_LIMIT            = "0.2";
        EMPTY_PRE_POST_CLEANUP = "yes";  # delete empty pre/post pairs
    };

    # ── snapper: /home ────────────────────────────────────────────────────────
    services.snapper.configs.home = {
        SUBVOLUME    = "/home";
        ALLOW_GROUPS = [ "wheel" ];
        ALLOW_USERS  = [ "thadfake" ];  # user can manage their own home snapshots

        TIMELINE_CREATE  = "yes";
        TIMELINE_CLEANUP = "yes";

        # Home changes more often — keep more recent granularity
        TIMELINE_LIMIT_HOURLY  = "24";
        TIMELINE_LIMIT_DAILY   = "14";
        TIMELINE_LIMIT_WEEKLY  = "8";
        TIMELINE_LIMIT_MONTHLY = "12";
        TIMELINE_LIMIT_YEARLY  = "3";

        SPACE_LIMIT            = "0.2";
        EMPTY_PRE_POST_CLEANUP = "yes";
    };

    # ── snapper: /opt/packages (@pkgs) ────────────────────────────────────────
    # Snapshot the package subvolume so container / AppImage installs can be
    # rolled back independently of the OS or home.
    services.snapper.configs.pkgs = {
        SUBVOLUME    = "/opt/packages";
        ALLOW_GROUPS = [ "wheel" "isolpkg" "syspkg" ];
        ALLOW_USERS  = [];

        TIMELINE_CREATE  = "yes";
        TIMELINE_CLEANUP = "yes";

        TIMELINE_LIMIT_HOURLY  = "6";
        TIMELINE_LIMIT_DAILY   = "7";
        TIMELINE_LIMIT_WEEKLY  = "4";
        TIMELINE_LIMIT_MONTHLY = "3";
        TIMELINE_LIMIT_YEARLY  = "1";

        SPACE_LIMIT            = "0.2";
        EMPTY_PRE_POST_CLEANUP = "yes";
    };

    # ── btrbk: backup to external drive ──────────────────────────────────────
    # btrbk sends incremental snapshots to an external btrfs drive.
    # Mount the target drive at /mnt/backup before running btrbk.
    #
    # To trigger a backup manually: sudo btrbk run
    # To schedule via systemd timer: set services.btrbk.instances.main.onCalendar
    #
    # Uncomment and adjust paths to activate.
    #
    # services.btrbk.instances.main = {
    #     onCalendar = "daily";
    #     settings = {
    #         timestamp_format    = "long";
    #         snapshot_preserve_min = "2d";
    #         snapshot_preserve   = "7d 4w 6m";
    #         target_preserve_min = "no";
    #         target_preserve     = "20d 10w 12m";
    #         volume."/".subvolume."@" = {
    #             snapshot_dir  = "/.snapshots";
    #             target        = "/mnt/backup/snapshots/root";
    #         };
    #         volume."/".subvolume."@home" = {
    #             snapshot_dir  = "/home/.snapshots";
    #             target        = "/mnt/backup/snapshots/home";
    #         };
    #     };
    # };

    # ── Shell Alias: rebuild with pre/post snapshot ────────────────────────────
    # Usage: rebuild-snap switch | boot | test
    # Creates a numbered pre-snapshot, runs nixos-rebuild, creates post-snapshot.
    # If the rebuild fails the pre-snapshot is still useful for diffing.
    environment.shellAliases = {
        rebuild-snap = ''
            PRE=$(snapper -c root create --type pre --cleanup-algorithm number \
                          --print-number --description "pre-rebuild") && \
            nixos-rebuild "$@" ; \
            POST=$(snapper -c root create --type post --cleanup-algorithm number \
                           --print-number --pre-number "$PRE" --description "post-rebuild") && \
            echo "Snapshot pair: pre=$PRE post=$POST"
        '';
        # List root snapshots (shorthand)
        snaps = "snapper -c root list";
        # Browse snapshots in the TUI
        snap-ui = "btrfs-assistant";
    };
}
