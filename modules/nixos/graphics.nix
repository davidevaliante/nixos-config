{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;   # 32-bit OpenGL/Vulkan for Steam, Wine, older Electron
    extraPackages = with pkgs; [
      intel-media-driver  # iHD VA-API driver for 11th gen Intel and newer (Raptor Lake = 13th gen)
      vpl-gpu-rt          # Intel oneVPL runtime, replaces media-sdk for video encode/decode
      libvdpau-va-gl      # VDPAU shim → VA-API, for the few apps that still ask for VDPAU
    ];
  };

  # Without this, libva tries the legacy `i965` driver and fails with
  # `va_openDriver() returns -1`, killing hardware video decode in Chrome/Slack/etc.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # The discrete NVIDIA RTX 4060 (Max-Q) is fully disabled. `nouveau` is the
  # in-kernel open-source driver — it's slow, has no CUDA/working VDPAU, and
  # was implicated in DRM/KMS handoff issues during display-manager restarts.
  # Blacklisting it leaves the dGPU powered down (Intel iGPU handles
  # everything). Switch to the proprietary `nvidia` driver in PRIME offload
  # mode if/when CUDA, gaming, or ML workloads become real needs.
  boot.blacklistedKernelModules = [ "nouveau" ];
}
