{ desktopLib, ... }:

let
  inherit (desktopLib) cmdsStr;
in
{
  # Authored as raw config (instead of `settings.bind = [ ... ]`) so we can
  # interleave `# N. CATEGORY` comments and trailing `#"description"`
  # annotations. The keybind-cheatsheet noctalia plugin requires both to
  # render the Hyprland cheat sheet — without them the panel is empty.
  # Hyprland itself treats `#` as a line/trailing comment, so this is a no-op
  # for the compositor.
  wayland.windowManager.hyprland.extraConfig = ''
    # 1. Applications
    bind = $mod, RETURN, exec, $terminal #"Terminal"
    bind = $mod, B, exec, $browser #"Browser"
    bind = $mod, SPACE, exec, ${cmdsStr.launcher} #"Launcher"
    bind = $mod, T, exec, theme-switch #"Switch theme"

    # 2. Window Management
    bind = $mod, Q, killactive, #"Close window"
    bind = $mod SHIFT, V, togglefloating, #"Toggle floating"
    bind = $mod, F, fullscreen, 0 #"Toggle fullscreen"
    bind = $mod, P, pseudo, #"Toggle pseudo"
    bind = $mod, J, togglesplit, #"Toggle split direction"
    bind = $mod SHIFT, M, movetoworkspacesilent, special:stash #"Stash window"
    bind = $mod, M, togglespecialworkspace, stash #"Toggle stash"

    # 3. Window Focus
    bind = $mod, h, movefocus, l #"Focus left"
    bind = $mod, l, movefocus, r #"Focus right"
    bind = $mod, k, movefocus, u #"Focus up"
    bind = $mod, j, movefocus, d #"Focus down"

    # 4. Workspaces
    bind = $mod, 1, workspace, 1 #"Workspace 1"
    bind = $mod, 2, workspace, 2 #"Workspace 2"
    bind = $mod, 3, workspace, 3 #"Workspace 3"
    bind = $mod, 4, workspace, 4 #"Workspace 4"
    bind = $mod, 5, workspace, 5 #"Workspace 5"
    bind = $mod, 6, workspace, 6 #"Workspace 6"
    bind = $mod, 7, workspace, 7 #"Workspace 7"
    bind = $mod, 8, workspace, 8 #"Workspace 8"
    bind = $mod, 9, workspace, 9 #"Workspace 9"
    bind = $mod, 0, workspace, 10 #"Workspace 10"

    # 5. Move Window to Workspace
    bind = $mod SHIFT, 1, movetoworkspace, 1 #"Move to workspace 1"
    bind = $mod SHIFT, 2, movetoworkspace, 2 #"Move to workspace 2"
    bind = $mod SHIFT, 3, movetoworkspace, 3 #"Move to workspace 3"
    bind = $mod SHIFT, 4, movetoworkspace, 4 #"Move to workspace 4"
    bind = $mod SHIFT, 5, movetoworkspace, 5 #"Move to workspace 5"
    bind = $mod SHIFT, 6, movetoworkspace, 6 #"Move to workspace 6"
    bind = $mod SHIFT, 7, movetoworkspace, 7 #"Move to workspace 7"
    bind = $mod SHIFT, 8, movetoworkspace, 8 #"Move to workspace 8"
    bind = $mod SHIFT, 9, movetoworkspace, 9 #"Move to workspace 9"
    bind = $mod SHIFT, 0, movetoworkspace, 10 #"Move to workspace 10"

    # 6. Screenshots
    bind = $mod, S, exec, hyprshot -m region -o ~/Pictures/Screenshots #"Screenshot region"
    bind = $mod SHIFT, S, exec, hyprshot -m window -o ~/Pictures/Screenshots #"Screenshot window"
    bind = $mod CTRL, S, exec, hyprshot -m output -o ~/Pictures/Screenshots #"Screenshot output"

    # 7. System
    bind = $mod, escape, exec, ${cmdsStr.lock} #"Lock screen"
    bind = $mod ALT, L, exec, ${cmdsStr.lock} #"Lock screen"
    bind = $mod SHIFT, E, exec, ${cmdsStr.session} #"Session menu"
    bind = $mod SHIFT, Q, exit, #"Exit Hyprland"

    # 8. Noctalia
    bind = $mod, N, exec, ${cmdsStr.notify} #"Notification history"
    bind = $mod, slash, exec, ${cmdsStr.cheatsheet} #"Keybindings cheatsheet"
    bind = $mod, V, exec, ${cmdsStr.clipboard} #"Clipboard history"

    # 9. Mouse
    bindm = $mod, mouse:272, movewindow #"Move window"
    bindm = $mod, mouse:273, resizewindow #"Resize window"

    # 10. Audio
    bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ #"Volume up"
    bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- #"Volume down"
    bindel = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle #"Mute"
    bindl = , XF86AudioPlay, exec, playerctl play-pause #"Play / pause"
    bindl = , XF86AudioNext, exec, playerctl next #"Next track"
    bindl = , XF86AudioPrev, exec, playerctl previous #"Previous track"

    # 11. Brightness
    bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+ #"Brightness up"
    bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%- #"Brightness down"
  '';
}
