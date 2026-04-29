{ lib, ... }:

{
  # Tiny replacement for the npm `awsp` tool: fuzzy-pick a profile from
  # ~/.aws/credentials and export AWS_PROFILE in the current shell.
  # `awspc` clears the env var (back to the implicit `default` profile).
  programs.zsh.initContent = lib.mkAfter ''
    awsp() {
      [ -r "$HOME/.aws/credentials" ] || { print -u2 "awsp: ~/.aws/credentials not readable"; return 1; }
      local profile
      profile=$(grep -oP '^\[\K[^]]+' "$HOME/.aws/credentials" | fzf --prompt="AWS profile> " --height=40% --reverse) || return 0
      if [ "$profile" = "default" ]; then
        unset AWS_PROFILE
        print "AWS_PROFILE unset (using default)"
      else
        export AWS_PROFILE="$profile"
        print "AWS_PROFILE=$AWS_PROFILE"
      fi
    }

    awspc() { unset AWS_PROFILE; print "AWS_PROFILE cleared"; }
  '';
}
