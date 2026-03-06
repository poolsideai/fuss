#!/usr/bin/env bash
set -eux

upper="$(mktemp -d /tmp/fuss-gittest-upper.XXXXXX)"
mountpoint="$(mktemp -d /tmp/fuss-gittest-mnt.XXXXXX)"
cleanup() { rm -rf "$upper" "$mountpoint"; }
trap cleanup EXIT INT TERM

lowerdir="$(pwd)"
echo "Running git read-only checks through fuss at $mountpoint"

go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  git -C "$mountpoint" rev-parse --is-inside-work-tree | grep -qx true
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  git -C "$mountpoint" rev-parse --git-dir | grep -qx .git
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  git -C "$mountpoint" status --porcelain >/dev/null
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  git -C "$mountpoint" show -s --format=%H HEAD >/dev/null
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  git -C "$mountpoint" ls-files >/dev/null
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'find "$1/pkg/" >/dev/null' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'printf "fuss\n" > "$1/.fuss-add-test" && git -C "$1" add .fuss-add-test && git -C "$1" diff --cached --name-only -- .fuss-add-test | grep -qx .fuss-add-test' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'mkdir "$1/.fuss-mkdir-test" && test -d "$1/.fuss-mkdir-test"' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'touch "$1/.fuss-link-src" && ln "$1/.fuss-link-src" "$1/.fuss-link-dst" && test -f "$1/.fuss-link-dst"' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c ': > "$1/.fuss-creat-test" && test -f "$1/.fuss-creat-test"' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'ln -s .fuss-link-src "$1/.fuss-symlink-test" && test -L "$1/.fuss-symlink-test"' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c 'chmod 600 "$1/.fuss-creat-test" && truncate -s 1 "$1/.fuss-creat-test" && touch "$1/.fuss-creat-test"' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c '
    chown "$(id -u):$(id -g)" "$1/.fuss-creat-test" >/dev/null 2>&1 || true
    chown -h "$(id -u):$(id -g)" "$1/.fuss-symlink-test" >/dev/null 2>&1 || true
    mknod "$1/.fuss-mknod-test" p >/dev/null 2>&1 || true
  ' -- "$mountpoint"
go run ./cmd/fuss --lowerdir "$lowerdir" --upperdir "$upper" --mountpoint "$mountpoint" -- \
  sh -c '
    b="fuss-test-branch-$$"
    git -C "$1" branch "$b"
    git -C "$1" rev-parse --verify "$b" >/dev/null
    git -C "$1" branch -D "$b" >/dev/null
    ! git -C "$1" rev-parse --verify "$b" >/dev/null 2>&1
  ' -- "$mountpoint"

echo "gittest passed"
