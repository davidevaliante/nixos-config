{ pkgs, ... }:

{
  # 32-bit graphics libraries are already enabled by the nvidia/intel graphics
  # modules — Steam's runtime and most Proton games still need them.
  programs.steam = {
    enable = true;

    # Proton-GE ships fixes ahead of Valve's Proton (DXVK/VKD3D bumps,
    # media-foundation codecs, EAC/BattlEye glue). MTG Arena specifically
    # wants a recent Proton to render its Unity webview cleanly.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
}
