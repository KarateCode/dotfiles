#!/bin/bash
#
# macos-defaults.sh -- Set macOS preferences
#
# Run this script after a fresh macOS install or when you want to reset preferences.
# Requires logout/restart for some settings to take effect.

set -e

echo "Setting macOS defaults..."

# ====================
# Keyboard
# ====================

# Initial delay before key repeat starts (default 15 ≈ 225ms)
# Lower = shorter delay. Value 17 ≈ 250ms
defaults write -g InitialKeyRepeat -int 17

# Key repeat rate (default 2 ≈ 30ms between repeats)
# Lower = faster. Value 1 = fastest (~15ms)
defaults write -g KeyRepeat -int 1

echo "Done! Log out and back in for changes to take effect."
