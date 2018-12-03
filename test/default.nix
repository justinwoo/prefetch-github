let
  pkgs = import <nixpkgs> {};

  prefetch-github = import ../. { inherit pkgs; };

in pkgs.stdenv.mkDerivation {
  name = "test";
  buildInputs = [
    prefetch-github
  ];
}
