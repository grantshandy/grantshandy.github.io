{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        tailwindcss = pkgs.nodePackages.tailwindcss.overrideAttrs
          (oa: {
            plugins = [
              pkgs.nodePackages."@tailwindcss/typography"
              (import ./daisyui.nix { inherit pkgs; })
            ];
          });

        build_css = pkgs.writeShellScriptBin "build_css"
          ''
            ${tailwindcss}/bin/tailwindcss --minify -i styles/styles.css -o static/styles.css
          '';

        link_katex = let src = pkgs.fetchzip {
          url = "https://github.com/KaTeX/KaTeX/releases/download/v0.16.9/katex.zip";
          hash = "sha256-Nca52SW4Q0P5/fllDFQEaOQyak7ojCs0ShlqJ1mWZOM=";
        }; in pkgs.writeShellScriptBin "link_katex"
          ''
            ln -s ${src} static/katex
          '';
        
        build_cmd = pkgs.writeShellScriptBin "build"
          ''
            ${build_css}/bin/build_css && ${pkgs.zola}/bin/zola serve
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

          
          buildInputs = buildInputs ++ [
            (pkgs.writeShellScriptBin "develop"
              ''
                ${pkgs.watchexec}/bin/watchexec -r -e html,md -- ${build_cmd}/bin/build
              '')
            build_cmd
          ];
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
