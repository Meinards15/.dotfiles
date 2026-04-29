{
    description = "nixos dotfiles da silva";

    inputs = { 
        ## Flakes Setup
        # [ Default Channel - NixOS-unstable ]
        nixpkgs.url             = "github:NixOS/nixpkgs/nixos-unstable";
        nixpkgs-stable.url      = "github:NixOS/nixpkgs/nixos-25.11";
        nixpkgs-oldstable.url   = "github:NixOS/nixpkgs/nixos-25.05";

        flake-parts.url         = "github:hercules-ci/flake-parts";
        import-tree.url         = "github:denful/import-tree";
        wrapper-modules.url     = "github:BirdeeHub/nix-wrapper-modules";
        impermanence.uril       = "github:nix-community/impermanence";

        ## Custom Repository
        # custom-repo = {
        #     url = "git+ssh://server/repoPath";
        #     url = "git+file:///srv/repos/repoPath";
        # };

        ## Custom Packages
        # Home Manager - [ Version = NixOS Version ]
        home-manager = {
            url = "github:nix-community/home-manager/release-25.11";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # NixOS Kernel - [ Custom CachyOS-kernel Port ]
        nix-cachyos-kernel = {
            url = "github:xddxdd/nix-cachyos-kernel/release";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Niri - [ Desktop Environment ]
        niri = {
            url = "github:YaLTeR/niri";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Agenix
        agenix = {
            url = "github:ryantm/agenix";
            inputs.nixpkgs.follows = "nixpkgs";
        };

        # Impermanence
        # Pairs with a @blank btrfs subvolume for a clean-slate root each boot.
        impermanence.url = "github:nix-community/impermanence";
    };

    outputs = { flake-parts, nix-cachyos-kernel, impermanence, agenix, home-manager, ... }@inputs:
        flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-linux" ];

            imports = [
                ./modules/default.nix
            ];

            nixosConfigurations = {
                maquina = inputs.nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    specialArgs = { inherit inputs; };
                    modules = [
                        ## /modules/hosts/maquina
                        ./hosts/maquina/configuration.nix
                        impermanence.nixosModules.impermanence
                        agenix.nixosModules.age
                        home-manager.nixosModules.home-manager
                        {
                            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.default ];
                            boot.kernelPackages = pkgs: pkgs.linuxPackages_cachyos;
                        }
                        {
                            home-manager = {
                                useGlobalPkgs = true;
                                useUserPackages = true;
                                users = {
                                    ## /modules/users/thadfake
                                    thadfake = import ./users/thadfake/home.nix;
                                };
                            };
                        }
                    ];
                };

                maquina-vm = inputs.nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    specialArgs = { inherit inputs; };
                    modules = [
                        impermanence.nixosModules.impermanence
                        agenix.nixosModules.age
                        ./hosts/maquina-vm/configuration.nix
                        home-manager.nixosModules.home-manager
                        {
                        home-manager = {
                            useGlobalPkgs = true;
                            useUserPackages = true;
                            users.thadfake = import ./users/thadfake/home.nix;
                            };
                        }
                    ];
                };
            };
        };

}
