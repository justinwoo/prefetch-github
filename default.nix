{ pkgs ? import <nixpkgs> {} }:

let
  binary = pkgs.rustPlatform.buildRustPackage rec {
    name = "prefetch-github-rs";
    version = "0.1.0";
    src = ./.;
    cargoSha256 = "0jacm96l1gw9nxwavqi1x4669cg6lzy9hr18zjpwlcyb3qkw9z7f";
  };

in pkgs.stdenv.mkDerivation {
  name = "prefetch-github";

  src = ./.;

  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    install -D -m555 -t $out/bin ${binary}/bin/prefetch-github

    wrapProgram $out/bin/prefetch-github \
      --prefix PATH : ${pkgs.lib.makeBinPath [
        pkgs.nix-prefetch-git
      ]}

    mkdir -p $out/etc/bash_completion.d/
    cp $src/prefetch-github-completion.bash $out/etc/bash_completion.d/prefetch-github-completion.bash
  '';
}
