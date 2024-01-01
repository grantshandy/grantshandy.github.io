{
  description = "A very basic flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = import nixpkgs { inherit system; };

        buildInputs = with pkgs; [
          zola
          nodePackages.npm
          nodejs_21
        ];

        nodeDependencies = (pkgs.callPackage ./tailwindcss.nix {}).nodeDependencies;

        website = pkgs.stdenv.mkDerivation rec {
          version = "0.0.1";
          name = "website";
          src = pkgs.lib.sourceByRegex ./. [
            "^content"
            "^content/.*"
            "^static"
            "^static/.*"
            "^templates"
            "^templates/.*"
            "^templates/macros"
            "^templates/macros.*"
            "^styles"
            "^styles/.*\.css"
            "tailwind.config.js"
            "config.toml"
          ];

          inherit buildInputs;

          checkPhase = "zola check";
          buildPhase = ''
            ln -s ${nodeDependencies}/lib/node_modules ./node_modules
            export PATH="${nodeDependencies}/bin:$PATH"

            npx tailwindcss -i styles/styles.css -o static/css/style.css
          '';
          installPhase = "zola build -o $out";
        };
      in {
        defaultPackage = website;

        devShell = pkgs.mkShell {
          inherit buildInputs;
        };
      });
}
