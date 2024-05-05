{ pkgs }: pkgs.buildNpmPackage rec {
  pname = "daisyui";
  version = "4.6.3";

  src = pkgs.fetchFromGitHub {
    owner = "saadeghi";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-O1YZF2mMNWnoj6sRrbQKJBTqlQ+NIcpZf0kawDDeVxM=";
  };

  npmDepsHash = "sha256-5qzMR2/QVde17Dk7+hsBVCMMKQXvRHXYm+/SCCkuTNs=";
  postPatch = ''
    cp ${./daisyui-package-lock.json} ./package-lock.json
  '';

  npmPackFlags = [ "--ignore-scripts" ];
  NODE_OPTIONS = "--openssl-legacy-provider";

  meta = with pkgs.lib; {
    description = "A free and open-source Tailwind CSS component library ";
    homepage = "https://daisyui.com/";
    license = licenses.mit;
  };
}
