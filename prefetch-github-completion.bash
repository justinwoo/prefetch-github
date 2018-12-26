#!/usr/bin/env bash

_prefetch-github() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-branch -fetchgit -hash-only -o -owner -r -repo -rev -v"

    case $prev in
        "-o" | "--owner")
            COMPREPLY=("justinwoo");
            return 0;;
        "-r" | "-repo")
            COMPREPLY=("prefetch-github");
            return 0;;
        "-v" | "-rev")
            COMPREPLY=("REVISION");
            return 0;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) );
            return 0;;
    esac
}

complete -F _prefetch-github prefetch-github
