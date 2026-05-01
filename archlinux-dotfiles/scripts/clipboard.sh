#!/usr/bin/env bash

cliphist list |
  fzf \
    --prompt="Clipboard ❯ " \
    --height=60% \
    --layout=reverse \
    --border \
    --preview='
      if echo {} | grep -q "image/"; then
        echo "[ image ]"
      else
        cliphist decode {} | sed -n "1,200p"
      fi
    ' \
    --preview-window=down:6:wrap |
  cliphist decode |
  wl-copy
