#!/usr/bin/env bash
wezterm start \
  --class cliphist-popup \
  --always-new-process \
  -- bash -c 'cliphist-archive-picker'

