{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  name = "make-tar";
  src = import ./default.nix {};
  shellHook = ''
    mkdir bin
    cp ${src}/bin/prefetch-github bin
    tar zcvf prefetch-github.tar.gz bin
  '';
}
