{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    katex = {
      url = "https://github.com/KaTeX/KaTeX/releases/download/v0.16.9/katex.zip";
      flake = false;
    };
  };

  outputs = { nixpkgs, utils, katex, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        tailwindcss = pkgs.nodePackages.tailwindcss.overrideAttrs
          (oa: {
            plugins = [
              pkgs.nodePackages."@tailwindcss/typography"
              (import ./nix/daisyui.nix { inherit pkgs; })
            ];
          });

        build_css = pkgs.writeShellScriptBin "build_css"
          ''
            ${tailwindcss}/bin/tailwindcss --minify -i styles/styles.css -o static/styles.css
          '';

        # let me know if there's a better way to do this :)
        link_katex = pkgs.writeShellScriptBin "link_katex"
          ''
            rm -rf static/katex
            ln -s ${katex} static/katex
          '';

        buildInputs = [ pkgs.zola build_css link_katex ];
      in
      {
        defaultPackage = pkgs.stdenv.mkDerivation {
          inherit buildInputs;

          version = "0.0.1";
          name = "grantshandy.github.io";
          src = ./.;

          checkPhase = "zola check";

          buildPhase = ''
            build_css
            link_katex
            zola build
          '';

          installPhase = ''
            mkdir -p $out/site
            cp -r public/* $out/site/
          '';
        };

        devShell = pkgs.mkShell {
          shellHook = "${link_katex}/bin/link_katex";
          buildInputs = buildInputs ++ [
            (pkgs.writeShellScriptBin "develop"
              ''
                ${pkgs.watchexec}/bin/watchexec -r -e html,md,css,json -- "${build_css}/bin/build_css && ${pkgs.zola}/bin/zola serve"
              '')
            tailwindcss
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
