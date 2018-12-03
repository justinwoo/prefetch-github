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
