#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function create_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  set -o errexit -o pipefail
  trap 'echo T: "Failed at $BASH_SOURCE line $LINENO: $BASH_COMMAND" >&2' ERR
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  exec </dev/null 11>&1 22>&2

  local PKG_NAME="$1"; shift || true
  [ "$#" == 0 ] || return 4$(echo E: "Unsupported CLI argument(s): $*" >&2)
  local VAL="${PKG_NAME//[^A-Za-z0-9_-]/}"
  [ -z "$VAL" ] || return 4$(
    echo E: "Unsupported characters in package name: $VAL" >&2)
  [ -n "$PKG_NAME" ] || PKG_NAME=.
  git init -- "$PKG_NAME"
  cd -- "$PKG_NAME"

  local YMD_HMS="$(printf -- '%(%y%m%d-%H%M%S)T' -1)"

  VAL="$(ls -d -- node_modules/eslint-* 2>/dev/null || true)"
  [ -n "$VAL" ] || guess-js-deps usy

  local MISSION_STMT_FILES='package.json README.md'
  VAL="$(ls -- $MISSION_STMT_FILES 2>/dev/null || true)"
  VAL="${VAL//$'\n'/ }"
  # [ -z "$VAL" ] || return 4$(echo E: "Flinching: Found file(s): $VAL" >&2)
  # ^-- Actually, we can determine missing steps reliable enough to safely
  #     upgrade existing projects without any risk of havoc.

  ( export VISUAL=true DISPLAY=
    [ -f .gitignore ] || gitig node_modules/ # from git-util-pmb
    [ -f package.json ] || new pkjs # from file-templates-pmb
    [ -f README.md ] || new readmd # from file-templates-pmb
  )
  readme-ssi
  github-configure-repo --skip=origin

  VAL="$(ls -d -- .git/refs/heads/ 2>/dev/null || true)"
  if [ -z "$VAL" ]; then
    git-ttcommit -20m --allow-empty --message='Init repo.'
    git branch init
  fi

  local DEST_DIR="$PWD"
  VAL='
    .github
    github-ci.yaml
    test
    '
  [ -z "$VAL" ] || (
    cd -- "$SELFPATH"
    echo 'Copy files:'
    cp --verbose --no-clobber --recursive --target-directory="$DEST_DIR" \
      -- $VAL | tee -- /proc/self/fd/11 | wc --lines |
      sed -re 's!\S+!Copied & files.!'
  )

  if all_files_unknown_to_git $MISSION_STMT_FILES; then
    # Pre-commit the mission statement for timestamp and commit message. File
    # content doesn't matter because I'll git-amend-forcepush it a lot anyway.
    git add -- $MISSION_STMT_FILES
    git ttcommit -17m --message='Mission statement.' -- $MISSION_STMT_FILES
  fi

  set -- .github/workflows/*.yaml github-ci.yaml
  if all_files_unknown_to_git "$@"; then
    git add -- "$@"
    git ttcommit -12m --message='[test] Configure GitHub CI.' -- "$@"
    git stash
    git branch ghci-$YMD_HMS
    git reset --hard HEAD~1
    ! git stash list | grep -m 1 -q . || git stash pop
  fi
}


function all_files_unknown_to_git () {
  local VAL="$(git status --porcelain -uall -- "$@" |
    cut --bytes=1-2 | LANG=C sort --uniq)"
  [ "$VAL" == '??' ]
}








create_cli_init "$@"; exit $?
