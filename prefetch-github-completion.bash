#!/usr/bin/env bash

_prefetch-github() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="-branch -fetchgit -hash-only -owner -repo -rev"

    case $prev in
        "-owner")
            COMPREPLY=("justinwoo");
            return 0;;
        "-repo")
            COMPREPLY=("prefetch-github");
            return 0;;
        "-rev")
            COMPREPLY=("REVISION");
            return 0;;
        *)
            # shellcheck disable=SC2207
            # shellcheck disable=SC2086
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) );
            return 0;;
    esac
}

complete -F _prefetch-github prefetch-github
