{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;   # 32-bit OpenGL/Vulkan for Steam, Wine, older Electron
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Required for Wayland (Hyprland/Niri). Without modesetting, KMS handoff
    # breaks during DM start and external monitors don't get assigned.
    modesetting.enable = true;

    # The 3060 Ti is Ampere — supported by NVIDIA's open kernel modules
    # (Turing+). The open driver is now the recommended default; closes
    # parity with the proprietary blob for non-CUDA desktop workloads and
    # avoids GBM-related issues on Wayland.
    open = true;

    nvidiaSettings = true;

    # Without this, VRAM contents are lost across suspend and the GPU comes
    # back with no valid framebuffer — the symptom is a Wayland session that
    # can't repaint after resume (monitor cycles on/off, fan audible, no
    # image). Enabling this sets NVreg_PreserveVideoMemoryAllocations=1 and
    # wires up nvidia-suspend/nvidia-resume.service to snapshot VRAM to
    # /tmp/nvidia and restore it on wake.
    powerManagement.enable = true;

    # Pin to the stable production driver. Switch to `production` for newer
    # GPUs or `beta` only if a specific bug fix requires it.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland environment hints. NVIDIA's EGL/GBM stack only kicks in for the
  # nvidia backend when these are explicit — many Electron/Chromium apps
  # otherwise fall through to llvmpipe and render at single-digit FPS.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
