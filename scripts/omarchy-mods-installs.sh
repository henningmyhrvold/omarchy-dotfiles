#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

#Install go
omarchy install dev-env go

#Install rust
omarchy install dev-env rust

#Install python
omarchy install dev-env python

#Install vscode
omarchy install editor vscode

#Install signal
omarchy install service signal


