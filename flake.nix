{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    serpantinum.url = "github:ilyamiro/serpantinum";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";

    # Pannello degli agenti per serpantinum: progetto locale (quando sarà su GitHub:
    # url = "github:valerio-bosco/oring"). Dopo ogni modifica al progetto: nix flake update oring
    oring = {
      url = "path:/home/voodoo/Projects/oring";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./configuration.nix

        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

        # Overlay di Claude Code: pkgs.claude-code diventa la versione del flake
        {
          nixpkgs.overlays = [ inputs.claude-code.overlays.default ];
        }
      ];
    };
  };
}
