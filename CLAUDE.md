Overall task : building a refining a nixos configuration that i can share across all my daily driversj

Core ideas:
- secret/sensitive configuration managements in a secure way. All sensitie informations like API_KEYS, VPN configs, password etc should be stored in a secure way and used automatically by the hosting machine
- theme switching (given some themes i need to seamlessly switch between them if i want)
- different wayland compositors support (i want both Hyprland and Niri since i'm not sure which one i want to use). All should follow the predefined color scheme
- do not reinvent the wheel, search and prefer existing programs when possible
- notification handling and history is a must
- screenshot and screensharing are a must
- everything has to be styled beatifully (and based on theme)
- make a research of popular nixos/arch repos for professional and beautiful configurations

Preferences about the programs to install :
- zsh (with autocompletion and other commonly used plugins)
- eza with useful aliases
- starship (simple and clean)
- zoxide
- neovim will be the main editor (keep default configuration later, we'll tackle this after since my config is extremely customized
- openvpn connect
- bottom (btm)

Packages i used for work and that will need very specific version and profile switching
- aws cli
- eks
- kubectl
- opentofu


