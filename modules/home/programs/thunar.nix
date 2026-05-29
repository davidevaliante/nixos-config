{ ... }:

{
  # Thunar custom actions live in ~/.config/Thunar/uca.xml. Managing it
  # declaratively means the GUI "Configure custom actions" dialog can no longer
  # save edits (the file is a read-only nix-store symlink) — add new entries
  # here instead.
  #
  # Substitutions inside <command>: %F = all selected paths (shell-quoted),
  # %f = first selected path, %% = literal %. Hence `printf "%%s\n"` ends up
  # as `printf "%s\n"` in the spawned shell.
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon>edit-copy</icon>
    	<name>Copy path</name>
    	<submenu></submenu>
    	<unique-id>nixos-copy-path-1</unique-id>
    	<command>sh -c 'printf "%%s\n" "$@" | wl-copy --trim-newline' _ %F</command>
    	<description>Copy full path(s) of selected items to the clipboard</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    	<audio-files/>
    	<image-files/>
    	<other-files/>
    	<text-files/>
    	<video-files/>
    </action>
    </actions>
  '';
}
