{ pkgs, ... }:

let
  wifiPicker = pkgs.writeShellApplication {
    name = "wifi-picker";
    runtimeInputs = with pkgs; [ networkmanager fuzzel libnotify gnused gawk ];
    text = ''
      nmcli -t device wifi rescan 2>/dev/null || true

      networks=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list \
        | awk -F: '
          $2 != "" {
            indicator = ($1 == "*") ? " " : "  "
            sec = ($4 == "" || $4 == "--") ? "" : " "
            printf "%s%s%s  (%s%%)\n", indicator, $2, sec, $3
          }
        ' \
        | sort -u)

      [ -z "$networks" ] && {
        notify-send "WiFi" "No networks found" -t 3000
        exit 0
      }

      choice=$(printf '%s\n' "$networks" | fuzzel --dmenu --prompt "    " --lines 8 --width 42)
      [ -z "$choice" ] && exit 0

      ssid=$(printf '%s' "$choice" | sed -E 's/^[ ✓]+//; s/ +$//; s/ +\([0-9]+%\)$//; s/  *$//')

      if nmcli -t device wifi connect "$ssid" >/dev/null 2>&1; then
        notify-send "WiFi" "Connected to $ssid" -t 3000
        exit 0
      fi

      pw=$(fuzzel --dmenu --password --prompt "  $ssid: " --lines 0 --width 42)
      [ -z "$pw" ] && exit 1

      if nmcli -t device wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
        notify-send "WiFi" "Connected to $ssid" -t 3000
      else
        notify-send -u critical "WiFi" "Failed to connect to $ssid"
        exit 1
      fi
    '';
  };
in
{
  home.packages = with pkgs; [
    pwvucontrol
    networkmanagerapplet
    gnome-calendar
    wifiPicker
  ];
}
