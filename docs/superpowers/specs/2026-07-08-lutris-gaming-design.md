# Lutris on `helium` — Design

**Date:** 2026-07-08
**Goal:** Be able to install and play the uaRO Ragnarok Online private server (`uaro.kiev.ua`, Pre-Renewal Ep. 11.2) on the `helium` host. uaRO ships a Windows client; Lutris manages the Wine prefix and has a community installer for it (listed on lutris.net as a 2023 Windows MMORPG).

## Scope

- Host: `helium` only (the desktop that already has Steam, nvidia, and 32-bit graphics).
- Tooling: Lutris + Wine only. No gamemode/gamescope/mangohud (can be added later if wanted).
- The Nix config provides **generic gaming infrastructure**. uaRO itself is installed at runtime through Lutris, not hardcoded in Nix.

## Approach

New self-contained NixOS module `modules/nixos/lutris.nix`, mirroring the existing `modules/nixos/steam.nix`, imported only by `hosts/helium/default.nix`.

Install `pkgs.lutris` overridden with `extraPkgs` so Wine + winetricks and the common runtime libraries old DirectX games (like RO) expect are available to Lutris's runners. Bare `pkgs.lutris` was rejected because Lutris's auto-downloaded Wine runners are unreliable on NixOS and it ships no winetricks; a home-manager module was rejected for consistency, since Steam and the 32-bit graphics stack are already system-level modules.

### Module contents

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.lutris.override {
      extraPkgs = pkgs: [
        pkgs.wineWowPackages.stable   # 32+64-bit wine; RO client is 32-bit
        pkgs.winetricks
      ];
    })
  ];
}
```

Relies on already-enabled pieces (no duplication):
- `hardware.graphics.enable32Bit` — from `modules/nixos/graphics/nvidia.nix`.
- Proton-GE + Steam runtime — from `modules/nixos/steam.nix`.

### Integration

Add one import line to `hosts/helium/default.nix`, next to the `steam.nix` import.

## Dependencies

- `modules/nixos/graphics/nvidia.nix` (32-bit graphics) — already imported by helium.
- `modules/nixos/steam.nix` — already imported by helium.

## Testing / verification

- `nixos-rebuild build` (or the repo's `nix-switch`) evaluates and builds successfully.
- `lutris` launches after activation.
- Manual runtime step (out of scope for Nix): open Lutris → search "uaRO" → Install → register at uaro.kiev.ua when the client prompts.

## Out of scope

- gamemode / gamescope / mangohud.
- Any per-game uaRO configuration in Nix.
- Second host (`hydrogen`).
