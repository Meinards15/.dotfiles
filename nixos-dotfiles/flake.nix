{
    description = "nixos dotfiles da silva";

    inputs = {
        ## NixPKGs Channels
        nixpkgs.url           = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs-stable.url    = "github:NixOs/nixpkgs/nixos-25.11";
        nixpkgs-oldstable.url = "github:NixOs/nixpkgs/nixos-25.05";

        ## Custom Repository
        # custom-repo = {
        #     url = "git+ssh://server/repoPath";
        #     url = "git+file:///srv/repos/repoPath";
        # };

        ## Flakes Setup
        flake-parts.url     = "github:hercules-ci/flake-parts";
        import-tree.url     = "github:vic/import-tree";
        wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";

        ## Home Manager [ Change Versions ]
        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        ## Custom CachyOS made for NixOS
        nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel";

        # ── Niri Compositor ───────────────────────────────────────────────────
        # Uncomment to track niri master ahead of nixpkgs.
        # niri.url = "github:YaLTeR/niri";

        # ── Secrets — agenix ──────────────────────────────────────────────────
        # age-encrypted secrets committed to the repo; decrypted at activation.
        # Workflow: edit secret → `agenix -e secret.age` → commit .age file.
        # agenix = {
        #     url = "github:ryantm/agenix";
        #     inputs.nixpkgs.follows = "nixpkgs";
        # };

        # ── Impermanence (optional) ────────────────────────────────────────────
        # Wipes / on every boot; only explicitly declared paths survive.
        # Pairs with a @blank btrfs subvolume for a clean-slate root each boot.
        # impermanence.url = "github:nix-community/impermanence";
    };

    outputs = inputs@{ flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            imports = [ ./modules ];
        };
}
