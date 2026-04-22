#!/bin/bash

DOTFILES="$(pwd)"

cd "$DOTFILES/configs"
find . -type f | while read -r file; do
    file="${file#./}"
   
    target="$HOME/$file"
    
    mkdir -p "$(dirname "$target")"
    ln -sf "$DOTFILES/configs/$file" "$target"
    echo "Created Sym Link: $target"
done
