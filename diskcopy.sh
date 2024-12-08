#!/usr/bin/env bash

set -euo pipefail

function errcho() {
    echo "$@" >&2
}

if [[ $# -ne 1 ]]; then
    errcho "usage: $0 <src>"
    exit 1
fi

src="$1"

if [[ -e "cdimage" ]]; then
    errcho "cdimage exists, validating blkid"
    ours=$(blkid cdimage | cut -d':' -f2-)
    theirs=$(blkid "$src" | cut -d':' -f2-)
    if [[ "$ours" != "$theirs" ]]; then
        errcho "blkid mismatch"
        errcho "    ours=$ours"
        errcho "  theirs=$theirs"
        exit 1
    else
        errcho "existing image, continuing copy"
    fi
fi

if [[ -e "rdir" ]]; then
    direction=$(cat "rdir")
else
    direction="f"
fi

if [[ ! -e "phase" ]]; then
    errcho "phase 1: no-scrape copy"
    if [[ "$direction" == "f" ]]; then
        ddrescue -n -b2048 -v "$src" cdimage mapfile
    else
        errcho "reversing direction of all passes"
        ddrescue -R -n -b2048 -v "$src" cdimage mapfile
    fi
    echo "phase1" > phase
else
    errcho "phase exists, assuming phase 1 complete."
fi

errcho "phase 2: attempt rescue failed blocks"
ddrescue -d -r1 -b2048 "$src" cdimage mapfile
echo "phase2" > phase
