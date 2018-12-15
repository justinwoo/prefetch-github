# Prefetch-Github

[![Build Status](https://travis-ci.org/justinwoo/prefetch-github.svg?branch=master)](https://travis-ci.org/justinwoo/prefetch-github)

A helper to save me some keystrokes from `nix-prefetch-git`.

## Usage

```sh
> prefetch-github -owner justinwoo -repo spacchetti
{
  owner = "justinwoo";
  repo = "spacchetti";
  rev = "9c5661c7fa994c08932494600fb0fee1e0d6ce11";
  sha256 = "1d3x15qr4iw1gsswx6qhmmh1lmfh12fwdfi94gkkxiihnwimzfdm";
}
```

```sh
> prefetch-github -h
Usage of prefetch-github:
  -branch
        Treat the rev as a branch, where the commit reference should be used.
  -fetchgit
        Print the output in the fetchGit format. Default: fromFromGitHub
  -hash-only
        Print only the hash.
  -owner string
        The owner of the repository. e.g. justinwoo
  -repo string
        The repository name. e.g. easy-purescript-nix
  -rev string
        Optionally specify which revision should be fetched.
```

## Why another Prefetch GitHub tool? What's wrong with...

### `nix-prefetch-git`

Not that much, just that it's annoying to take its input and work with it personally.

### [`nix-prefetch-github`](https://github.com/seppeljordan/nix-prefetch-github)

This tool regularly does not successfully install for me through neither nixpkgs nor pip. I also hate Python for being irreproducible in general. I also have not found that its command line arguments are read in correctly, but this may have been addressed in other releases that I have not been able to install.
