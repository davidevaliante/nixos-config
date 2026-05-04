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

  # The discrete NVIDIA RTX 4060 (Max-Q) is left on `nouveau` and unused — Intel
  # iGPU handles everything. Enabling the proprietary `nvidia` driver + PRIME
  # offload is doable but adds significant complexity (signed kernel modules,
  # power-management quirks, suspend/resume issues). Revisit if/when CUDA or
  # serious 3D workloads become necessary.
}
