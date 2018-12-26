{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "prefetch-github";

  src = ./.;

  buildInputs = [
    pkgs.makeWrapper
    pkgs.go
  ];

  installPhase = ''
    go build prefetch-github.go
    install -D -m555 -t $out/bin prefetch-github

    wrapProgram $out/bin/prefetch-github \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.nix-prefetch-git
      ]}

    mkdir -p $out/etc/bash_completion.d/
    cp $src/prefetch-github-completion.bash $out/etc/bash_completion.d/prefetch-github-completion.bash
  '';
}
