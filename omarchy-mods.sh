#!/bin/bash
set -e
# One-time Omarchy customizations — run once by bootstrap.sh

# Theme hook for additional theme support
curl -fsSL https://imbypass.github.io/omarchy-theme-hook/install.sh | bash
sleep 2
curl -fsSL https://raw.githubusercontent.com/JacobusXIII/omarchy-wireguard-vpn-toggle/main/install.sh | bash
sleep 2

# Install extra themes
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-ayaka-theme
sleep 2
omarchy-theme-install https://github.com/JaxonWright/omarchy-midnight-theme
sleep 2
omarchy-theme-install https://github.com/bjarneo/omarchy-pulsar-theme
sleep 2
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-spectra-theme
sleep 2


#
#
#
#
#
#
#
#
#
