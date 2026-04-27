{ inputs, nixpkgs, ... }: {
    imports 
    nixosConfigurations.maquina = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
            self.nixosModules.maquinaConfig
            inputs.home-manager.nixosModules.home-manager
            {
                home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                    users.thadfake = import ../users/thadfake-home.nix;
                    backupFileExtension = "backup";
                };
            }
        ];
    };
}

