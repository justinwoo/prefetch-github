{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  name = "make-tar";
  buildInputs = [pkgs.cargo];
  src = ./.;
  shellHook = ''
    cargo build --release
    mv target/release/prefetch-github .
    mkdir -p bin
    mv prefetch-github bin
    tar zcvf prefetch-github.tar.gz bin
  '';
}
