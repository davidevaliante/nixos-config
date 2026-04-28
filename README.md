# nixos-config

Multi-host, multi-compositor NixOS flake — shared across daily drivers.

## Highlights

- **Compositors:** Hyprland (default) and Niri available side-by-side; pick at GDM. Both share the same waybar / swaync / fuzzel / kitty / hyprlock / wlogout stack.
- **Theme:** stylix-driven base16. Switch live with `Super+T` → fuzzel menu. Schemes: `oxocarbon-dark` (default), `catppuccin-mocha`, `tokyo-night-dark`, `synthwave-84`. Wallpaper gradient is theme-derived.
- **Secrets:** sops-nix with age. SSH keypair currently encrypted in repo. See [docs/sops.md](docs/sops.md) for the workflow.
- **Editor:** Neovim 0.11 (pinned via `nixpkgs-stable` input). Lua config lives at `~/.config/nvim`. LSPs/formatters declared in nix; Mason removed to avoid NixOS dynamic-linker pain.
- **Caches:** `cache.nixos.org` + `nix-community.cachix.org` + `niri.cachix.org` so community packages come pre-built.

## Daily commands (after first rebuild)

| Command | What |
|---|---|
| `rebuild` | `sudo nixos-rebuild switch` against this flake |
| `rebuildup` | `nix flake update` first, then rebuild |
| `nix-switch dry` | preview changes |
| `Super+T` | theme switcher |
| `Super+/` | keybind cheatsheet |
| `Super+Shift+E` | wlogout (lock/reboot/shutdown) |

## Layout

```
flake.nix              mkHost helper, inputs (nixpkgs / -stable / home-manager / sops / stylix / niri)
.theme                 active theme name, read at eval time
.sops.yaml             age recipients + creation rules
hosts/<hostname>/      per-host config + hardware-configuration
modules/nixos/         system: common, users, sops, stylix, openssh, desktops/
modules/nixos/themes/  custom base16 yamls (synthwave-84.yaml etc.)
modules/home/programs/ shell + cli: zsh/eza/starship/zoxide/bottom/git/neovim/nix-switch/ssh
modules/home/desktop/  compositor + wayland UX: waybar/swaync/fuzzel/kitty/hyprlock/...
home/<username>/       entry point — imports all home modules
secrets/{common,hosts/<hostname>}/   sops-encrypted yamls
scripts/sops-bootstrap.sh   idempotent helper for first machine + new hosts
docs/                  sops.md, smoke-test.md
```

## First machine bootstrap

1. Boot a NixOS installer, partition, mount, generate hardware config
2. Drop `hosts/<hostname>/hardware-configuration.nix` into the repo
3. `sudo nixos-rebuild switch --flake /path/to/repo#<hostname> --no-update-lock-file`
4. `bash scripts/sops-bootstrap.sh` once activated, then encrypt your first secret per [docs/sops.md](docs/sops.md)
5. Run [`docs/smoke-test.md`](docs/smoke-test.md) to confirm the desktop works as expected

## Adding a second machine

See [docs/sops.md](docs/sops.md) → "Adding a second machine". Short version: copy your user age key, run the bootstrap script, append the host's pubkey to `.sops.yaml`, `sops updatekeys`.

## Phases (project status)

- ✅ Restructure repo + base home-manager programs
- ✅ Stylix theming with live theme switching
- ✅ Hyprland + Niri (parallel installs)
- ✅ sops-nix with first secret (SSH key)
- ✅ Neovim hand-curated lua config + nix-managed LSPs
- ⏳ Phase 7 — work profile (aws-cli/kubectl/opentofu devshells, aws-vault)
- ⏳ Phase 8 — polish pass cross-referencing other public configs
