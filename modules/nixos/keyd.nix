{ ... }:

{
  # The Aula F75 ("BY Tech Gaming Keyboard", USB 258a:010c — a SinoWealth-based
  # board) has no dedicated Insert key. Its firmware maps the "Insert" keycap on
  # the Fn layer (Fn+Del) to Ctrl+Delete rather than a real KEY_INSERT — verified
  # with evtest: Fn+Del emits the ^[[3;5~ (Ctrl+Delete) sequence, plain Del emits
  # ^[[3~. The vendor config tool is Windows-only and doesn't allow remapping, so
  # uaRO (Wine/Lutris) never receives an Insert.
  #
  # Fix at the evdev layer with keyd, below Xwayland/Wine, so the game sees a
  # genuine KEY_INSERT. keyd modifier layers strip the triggering modifier from
  # explicitly-remapped keys (the same mechanism as the classic Ctrl+H → Backspace
  # recipe), so `control.delete = insert` turns the Ctrl+Delete chord into a clean
  # Insert with no leaked Ctrl. Scoped by `ids` to this keyboard only, so plain
  # Delete and every other device (incl. the G502, id 046d:c08b) are untouched.
  services.keyd = {
    enable = true;
    keyboards.aula-f75 = {
      ids = [ "258a:010c" ];
      settings.control.delete = "insert";
    };
  };
}
