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

        # let me know if there's a better way to do this :)
        link_katex = pkgs.writeShellScriptBin "link_katex"
          ''
            rm -rf static/katex
            ln -s ${katex} static/katex
          '';

        buildInputs = [ pkgs.zola link_katex ];
      in
      {
        defaultPackage = pkgs.stdenv.mkDerivation {
          inherit buildInputs;

          version = "0.0.1";
          name = "grantshandy.github.io";
          src = ./.;

          checkPhase = "zola check";

          buildPhase = ''
            link_katex
            zola build
          '';

          installPhase = ''
            mkdir -p $out/site
            cp -r public/* $out/site/
          '';
        };

        devShell = pkgs.mkShell {
          shellHook = "link_katex";
          inherit buildInputs;
        };

        formatter = pkgs.nixfmt-rfc-style;
      });
}
