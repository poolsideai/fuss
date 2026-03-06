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

echo "gittest passed"
