{ config, lib, pkgs, ... }:

let
  c = config.lib.stylix.colors.withHashtag;

  customCss = ''
    /* hyprdots-inspired styling, theme-aware via stylix */

    * {
      outline: none;
    }

    window,
    dialog {
      background-color: ${c.base00};
      color: ${c.base05};
    }

    /* ─── Header bar ─── */
    headerbar,
    .titlebar {
      background: linear-gradient(180deg, ${c.base01}, ${c.base00});
      border-bottom: 1px solid ${c.base02};
      color: ${c.base05};
      min-height: 44px;
      padding: 0 8px;
    }

    headerbar .title {
      color: ${c.base05};
      font-weight: 700;
    }

    headerbar .subtitle,
    headerbar label.dim-label {
      color: ${c.base04};
    }

    /* ─── Buttons ─── */
    button {
      background: alpha(${c.base02}, 0.7);
      color: ${c.base05};
      border: 1px solid alpha(${c.base02}, 0.5);
      border-radius: 10px;
      padding: 6px 14px;
      transition: all 180ms ease;
      box-shadow: none;
      text-shadow: none;
    }

    button:hover {
      background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
      color: ${c.base00};
      border-color: alpha(${c.base0E}, 0.5);
      box-shadow: 0 4px 12px alpha(${c.base0E}, 0.30);
    }

    button:active,
    button:checked {
      background: linear-gradient(135deg, ${c.base0E}, ${c.base0C});
      color: ${c.base00};
    }

    button.flat {
      background: transparent;
      border-color: transparent;
    }

    button.flat:hover {
      background: alpha(${c.base02}, 0.6);
      color: ${c.base05};
      box-shadow: none;
    }

    button.suggested-action {
      background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
      color: ${c.base00};
      border: none;
    }

    button.suggested-action:hover {
      box-shadow: 0 4px 14px alpha(${c.base0E}, 0.45);
    }

    button.destructive-action {
      background: linear-gradient(135deg, ${c.base08}, ${c.base09});
      color: ${c.base00};
      border: none;
    }

    button.destructive-action:hover {
      box-shadow: 0 4px 14px alpha(${c.base08}, 0.45);
    }

    /* circular close/menu buttons */
    button.circular,
    button.image-button {
      border-radius: 100%;
      min-width: 28px;
      min-height: 28px;
      padding: 4px;
    }

    /* ─── Entries ─── */
    entry,
    spinbutton {
      background: ${c.base01};
      color: ${c.base05};
      border: 1px solid ${c.base02};
      border-radius: 10px;
      padding: 8px 12px;
      transition: all 180ms ease;
      box-shadow: none;
    }

    entry:focus,
    spinbutton:focus {
      border-color: ${c.base0D};
      box-shadow: 0 0 0 2px alpha(${c.base0D}, 0.30);
    }

    entry selection,
    entry:selected {
      background: alpha(${c.base0D}, 0.4);
      color: ${c.base05};
    }

    /* ─── Sliders / progress ─── */
    scale trough,
    progressbar trough {
      background: ${c.base02};
      border: none;
      border-radius: 100px;
      min-height: 6px;
    }

    scale highlight,
    progressbar progress {
      background: linear-gradient(90deg, ${c.base0D}, ${c.base0E});
      border-radius: 100px;
      box-shadow: 0 0 8px alpha(${c.base0E}, 0.35);
    }

    scale slider {
      background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
      border: 2px solid ${c.base05};
      border-radius: 50%;
      min-width: 16px;
      min-height: 16px;
      margin: -8px;
      box-shadow: 0 2px 8px alpha(${c.base0E}, 0.40);
    }

    scale slider:hover {
      box-shadow: 0 4px 12px alpha(${c.base0E}, 0.55);
    }

    /* ─── Scrollbars ─── */
    scrollbar {
      background: transparent;
      border: none;
    }

    scrollbar slider {
      background: alpha(${c.base03}, 0.6);
      border-radius: 100px;
      min-width: 6px;
      min-height: 30px;
      margin: 2px;
      transition: all 200ms ease;
    }

    scrollbar slider:hover {
      background: ${c.base0D};
      min-width: 8px;
    }

    /* ─── Lists / rows ─── */
    list,
    listbox,
    treeview {
      background: transparent;
    }

    list row,
    listbox row,
    treeview > row {
      border-radius: 10px;
      padding: 8px 12px;
      margin: 2px 6px;
      transition: all 180ms ease;
    }

    list row:hover,
    listbox row:hover {
      background: alpha(${c.base02}, 0.5);
    }

    list row:selected,
    listbox row:selected,
    treeview > row:selected {
      background: linear-gradient(135deg, alpha(${c.base0D}, 0.30), alpha(${c.base0E}, 0.30));
      color: ${c.base05};
      box-shadow: inset 3px 0 0 ${c.base0E};
    }

    /* ─── Popovers / menus ─── */
    popover,
    popover.menu {
      background: ${c.base01};
      border: 1px solid ${c.base02};
      border-radius: 14px;
      padding: 4px;
      box-shadow: 0 12px 32px rgba(0, 0, 0, 0.50);
    }

    popover contents,
    popover.menu contents {
      background: transparent;
    }

    popover button,
    popover.menu modelbutton {
      border-radius: 8px;
      padding: 6px 10px;
      background: transparent;
      border: none;
      box-shadow: none;
    }

    popover button:hover,
    popover.menu modelbutton:hover {
      background: alpha(${c.base02}, 0.7);
      color: ${c.base05};
    }

    /* ─── Switches ─── */
    switch {
      background: ${c.base02};
      border-radius: 100px;
      min-width: 44px;
      min-height: 22px;
      border: 1px solid alpha(${c.base02}, 0.8);
    }

    switch:checked {
      background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
      border-color: alpha(${c.base0E}, 0.5);
      box-shadow: 0 0 12px alpha(${c.base0E}, 0.30);
    }

    switch slider {
      background: ${c.base05};
      border-radius: 100px;
      min-width: 18px;
      min-height: 18px;
      margin: 2px;
    }

    /* ─── Checkboxes / radios ─── */
    checkbutton check,
    checkbutton radio {
      background: ${c.base01};
      border: 1px solid ${c.base02};
      border-radius: 6px;
      min-width: 18px;
      min-height: 18px;
    }

    checkbutton radio {
      border-radius: 100%;
    }

    checkbutton check:checked,
    checkbutton radio:checked {
      background: linear-gradient(135deg, ${c.base0D}, ${c.base0E});
      border-color: ${c.base0E};
      color: ${c.base00};
      box-shadow: 0 0 8px alpha(${c.base0E}, 0.35);
    }

    /* ─── Tabs ─── */
    notebook,
    notebook header {
      background: ${c.base00};
      border: none;
    }

    notebook tab {
      background: transparent;
      color: ${c.base04};
      border-radius: 10px 10px 0 0;
      padding: 8px 14px;
      border: none;
    }

    notebook tab:checked {
      background: ${c.base01};
      color: ${c.base05};
      box-shadow: inset 0 -2px 0 ${c.base0E};
    }

    /* ─── Sidebar (gnome-calendar etc.) ─── */
    .sidebar,
    .navigation-sidebar,
    placessidebar {
      background: ${c.base01};
      border-right: 1px solid ${c.base02};
    }

    .sidebar list row,
    .navigation-sidebar row {
      margin: 3px 6px;
      border-radius: 10px;
    }

    /* ─── libadwaita specifics ─── */
    .card,
    .activatable.card {
      background: ${c.base01};
      border: 1px solid ${c.base02};
      border-radius: 14px;
      padding: 12px;
    }

    .accent {
      color: ${c.base0E};
    }

    .success { color: ${c.base0B}; }
    .warning { color: ${c.base09}; }
    .error   { color: ${c.base08}; }

    /* ─── Tooltips ─── */
    tooltip {
      background: ${c.base01};
      border: 1px solid ${c.base0D};
      border-radius: 10px;
      padding: 4px;
    }

    tooltip label {
      color: ${c.base05};
      padding: 4px 6px;
    }
  '';
in
{
  home.packages = with pkgs; [ adw-gtk3 ];

  gtk.enable = true;

  stylix.targets.gtk.extraCss = customCss;

  # libadwaita color scheme + accent (used by GTK4 / GNOME apps)
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      accent-color = "purple";
    };
  };
}
