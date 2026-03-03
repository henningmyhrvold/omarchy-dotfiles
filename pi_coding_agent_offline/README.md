# Pi Coding Agent Offline Bundle

## How to regenerate the bundle (run on an online machine)
```bash
cd ~/src/omarchy-dotfiles/pi-coding-agent-offline
./bundle.sh
```

This produces two tarballs:
- `pi-npm-global.tar.gz` — pi binary + node_modules (npm global prefix)
- `pi-agent-data.tar.gz` — pi extensions (oh-pi, ralph) + settings.json

Both must be committed to the dotfiles repo or transferred alongside it.

## What's inside

- `@mariozechner/pi-coding-agent` and all npm dependencies
- `oh-pi` extension (installed via `pi install npm:oh-pi`)
- `ralph` extension (installed via `pi install npm:ralph`)
- Pre-configured `settings.json` with extensions registered

## Fallback manual approach:
tar -czf pi-npm-global.tar.gz -C "$HOME" .npm-global
tar -czf pi-agent-data.tar.gz -C "$HOME" .pi
