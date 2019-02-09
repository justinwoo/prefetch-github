{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  name = "make-tar";
  buildInputs = [pkgs.ghc];
  src = ./.;
  shellHook = ''
    ghc -o prefetch-github prefetch-github.hs
    mkdir -p bin
    mv prefetch-github bin
    tar zcvf prefetch-github.tar.gz bin
  '';
}
