{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  name = "make-tar";
  buildInputs = [pkgs.go];
  src = ./.;
  shellHook = ''
    ${pkgs.go}/bin/go build prefetch-github.go
    mkdir -p bin
    mv prefetch-github bin
    tar zcvf prefetch-github.tar.gz bin
  '';
}
