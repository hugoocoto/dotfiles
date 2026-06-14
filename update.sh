#!/bin/bash
#
# ----------------
# DOTFILES MANAGER
# ----------------
#
# by Hugo Coto 

ROOT="$HOME/"
DOTS="$HOME/dotfiles/"

FILES="$(find . -type f ! -wholename ".gitignore" ! -wholename "$0" ! -wholename "*/.git/*" )"

for f in $FILES; do

    Rf="$(realpath -s -m "$ROOT/$f")"
    Df="$(realpath -s -m "$DOTS/$f")"
    DIR="$(dirname "$Rf")" 
    mkdir -p "$DIR"

    if   [ -L "$Rf" ]; then echo "OKK - link already exists [$Rf]" 
    elif [ -f "$Rf" ]; then echo "ERR - dest exists and it's a file [$Rf]" 
    elif [ -d "$Rf" ]; then echo "ERR - dest exists and it's a directory [$Rf]" 
    elif [ -e "$Rf" ]; then echo "ERR - dest exists [$Rf]"
    else 
        ln -s "$Df" "$DIR" && echo "NEW - link created [$Df -> $Rf]"
    fi
done

