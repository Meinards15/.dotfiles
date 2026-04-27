{
    inputs = {
        nixpkgs.url = "nixpkgs/nixos-25.11";
        flake-parts.url = "github:hercules-ci/flake-parts";
        import-tree.url = "github:vic/import-tree";
        wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
        # home-manager.nixosModules.home-manager
        home-manager.url = "github:nix-community/home-manager/release-25.11";
    };

    outputs = inputs: inputs.flake-parts.lib.mkFlake
        {inherit inputs;}
        (inputs.import-tree ./modules);
}
