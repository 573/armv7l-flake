{
  inputs = {
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    treefmt-nix,
    systems,
    ...
  } @ inputs: let
    rootPath = self;
    system = "armv7l-linux";
    eachSystem = f:
      nixpkgs.lib.genAttrs (import systems) (
        system:
          f nixpkgs.legacyPackages.${system}
      );
    treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ self.overlays.default ];
    };
  in {
    overlays.default = final: prev: {
      # https://gist.github.com/pbogdan/547fb6854500bc93995b486022f286f9
      haskell = prev.haskell // {
        packages = prev.haskell.packages // {
          ghc928 = prev.haskell.packages.ghc928.override {
	    overrides = hsSelf: hsSuper: {
	      time-compat = prev.haskell.lib.dontCheck hsSuper.time-compat;
            };
	  };
	};
      };
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      # https://discourse.nixos.org/t/trying-to-make-a-libreoffice-overlay-to-skip-checks-because-i-want-to-complicate-my-life/48708
    };

    nixosConfigurations.${system}.raspi2 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit pkgs inputs rootPath;
      };

      modules = [
        "${rootPath}/configuration.nix"
      ];
    };

    formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
  };
}
