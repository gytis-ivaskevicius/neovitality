{
  description = "Big Neovim Energy";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixpkgs-unstable;
    nixpkgs-jdtls.url = github:nixos/nixpkgs/35925104b195ff6bbab8f645c56ecc0af62f87fd;
    flake-utils.url = github:numtide/flake-utils;
    devshell.url = github:numtide/devshell;
    nur.url = github:nix-community/NUR;

    neovim = {
      url = github:neovim/neovim?dir=contrib;
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    vim-plugins-overlay = {
      url = github:vi-tality/vim-plugins-overlay;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, neovim, flake-utils, devshell, nur, vim-plugins-overlay, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs-jdtls = import inputs.nixpkgs-jdtls { inherit system; };
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
          overlays = [
            devshell.overlay
            vim-plugins-overlay.overlay
            neovim.overlay
            nur.overlay
            (final: prev: {
              python = prev.python3;
              jdt-language-server = pkgs-jdtls.jdt-language-server;
            })
          ];
        };
        neovimBuilder = import ./options/neovimBuilder.nix { inherit pkgs; };

        customNeovim = neovimBuilder {
          config = {
            vim = import ./defaults/defaultConfig.nix { inherit pkgs; };
          };
        };

      in
      rec {

        inherit neovimBuilder;

        overlays = {
          vim-plugins-overlay = vim-plugins-overlay.overlay;
        };

        packages.neovim-nightly = pkgs.neovim;

        defaultPackage = customNeovim.neovim;

        apps = {
          nvim = flake-utils.lib.mkApp {
            drv = defaultPackage;
            name = "nvim";
          };
        };

        defaultApp = apps.nvim;

        devShell = pkgs.devshell.mkShell {
          name = "neovitality";
          packages = with pkgs; [
            rnix-lsp
            nixpkgs-fmt
          ];

          commands = [ ];
        };

      }
    );
}
