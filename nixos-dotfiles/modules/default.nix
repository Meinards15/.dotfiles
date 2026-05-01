{ inputs, lib, ... }:

{
    imports = [
        (inputs.import-tree [
            ./core
            ./hardware
            ./security
            ./services
            ./features
        ])
    ];
}
