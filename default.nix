{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "prefetch-github";

  src = ./.;

  buildInputs = [
    pkgs.makeWrapper
  ];

  installPhase = ''
    install -D -m555 -t $out/bin prefetch-github

    wrapProgram $out/bin/prefetch-github \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.coreutils
        pkgs.perl
        pkgs.jq
        pkgs.nix-prefetch-git
      ]}
  '';
}
