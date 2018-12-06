{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  name = "make-tar";
  buildInputs = [pkgs.go];
  src = ./.;
  shellHook = ''
    go build prefetch-github.go
    mkdir bin
    mv prefetch-github bin
    tar zcvf prefetch-github.tar.gz bin
  '';
}
