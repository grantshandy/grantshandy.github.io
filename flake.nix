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
              pkgs.nodePackages."@tailwindcss/aspect-ratio"
              pkgs.nodePackages."@tailwindcss/forms"
              pkgs.nodePackages."@tailwindcss/line-clamp"
              pkgs.nodePackages."@tailwindcss/typography"
              (import ./daisyui.nix { inherit pkgs; })
            ];
          });

        buildCss = pkgs.writeShellScriptBin "build_css"
          ''
            ${tailwindcss}/bin/tailwindcss --minify -i styles/styles.css -o static/css/styles.css
          '';

        buildInputs = [ pkgs.zola buildCss ];
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
            zola build
          '';
          installPhase = ''
            mkdir -p $out/site
            cp -r public/* $out/site/
          '';
        };

        devShell = pkgs.mkShell {
          inherit buildInputs;
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
