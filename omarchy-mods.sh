#!/bin/bash
set -e
# One-time Omarchy customizations — run once by bootstrap.sh

# Theme hook for additional theme support
curl -fsSL https://imbypass.github.io/omarchy-theme-hook/install.sh | bash

# Install extra themes
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-spectra-theme
