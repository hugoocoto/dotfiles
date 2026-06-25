#!/bin/bash
#
# ----------------
# DOTFILES MANAGER
# ----------------
#
# by Hugo Coto

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$HOME"
DOTS="$HERE"
MAP="$DOTS/fs.map"
set -euo pipefail

FILES="$(git -C "$HERE" ls-files -z | tr '\0' '\n')"
if [ -f "$HERE/.dotignore" ]; then
    while IFS= read -r pattern || [ -n "$pattern" ]; do
        [[ "$pattern" =~ ^#|^$ ]] && continue
        FILES="$(grep -vF "$pattern" <<< "$FILES")"
    done < "$HERE/.dotignore"
fi

if [ -f "$MAP" ]; then
    while IFS='|' read -r f1 f2; do
        grep -qxF "${f1#"$DOTS/"}" <<< "$FILES" && continue
        if   [ -L "$f2" ]; then
            echo "DEL - Removing link [$f2]"
            rm "$f2"
            rmdir -p "$(dirname "$f2")" 2>/dev/null
        elif [ -f "$f2" ]; then echo "ERR - dest exists and it's a file [$f2]"
        elif [ -d "$f2" ]; then echo "ERR - dest exists and it's a directory [$f2]"
        elif [ -e "$f2" ]; then echo "ERR - dest exists and it's not a link [$f2]"
        fi
    done < "$MAP"
    rm "$MAP"
fi

count=0
while IFS= read -r f; do
    Rf="$ROOT/$f"
    Df="$DOTS/$f"
    DIR="${Rf%/*}"
    mkdir -p "$DIR"
    if   [ -L "$Rf" ]; then :
    elif [ -f "$Rf" ]; then echo "ERR - dest exists and it's a file [$Rf]"
    elif [ -d "$Rf" ]; then echo "ERR - dest exists and it's a directory [$Rf]"
    elif [ -e "$Rf" ]; then echo "ERR - dest exists [$Rf]"
    else
        ln -s "$Df" "$Rf" && echo "NEW - link created [$Df -> $Rf]"
        (( count++ ))
    fi
    echo "$Df|$Rf" >> "$MAP"
done <<< "$FILES"

if (( count == 0 )); then 
    echo "Everything is up to date"
else
    echo "$count link(s) created"
fi
