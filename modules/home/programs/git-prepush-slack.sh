# git-prepush-slack - (re)install a git pre-push hook that posts a Slack
# message listing the commits being pushed.
#
# Usage: git-prepush-slack [REPO_PATH]
#
#   REPO_PATH   Path to the target git repo (default: current directory).
#
# Same logic as the original eks/dev/terraform/utils/git_prepush_restore.sh,
# but NixOS-friendly (hooks use `#!/usr/bin/env bash` instead of the
# non-existent `/bin/bash`) and callable from anywhere against an explicit
# repo.
#
# Prerequisites: AWS CLI authenticated with access to the `dev/slack-api`
# secret in eu-central-1. aws/jq/git/curl are pinned via runtimeInputs.

# errexit / nounset / pipefail are set by writeShellApplication.

repo="${1:-$PWD}"

if ! git_dir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)"; then
    echo "error: '$repo' is not a git repository." >&2
    exit 1
fi

repo_name="$(basename "$(git -C "$repo" rev-parse --show-toplevel)")"
prepush_file="$git_dir/hooks/pre-push"

echo "Installing pre-push Slack hook into $prepush_file"

# Verify AWS creds before fetching the secret.
if ! aws sts get-caller-identity &>/dev/null; then
    echo "AWS CLI is not authorized. Please configure your credentials." >&2
    exit 1
fi

echo "Getting token and channel ID"
secret_json="$(aws secretsmanager get-secret-value \
    --secret-id dev/slack-api --region eu-central-1 \
    --query SecretString --output text)"
slackToken="$(jq -r '.slack_token' <<<"$secret_json")"
channelID="$(jq -r '.slack_channel_id' <<<"$secret_json")"

read -r -p "Enter your name for notifications: " slackUser
if [[ -z "$slackUser" ]]; then
    echo "Name is empty. Exiting." >&2
    exit 1
fi

cat > "$prepush_file" <<EOF
#!/usr/bin/env bash

res=''
export IFS=\$'\n'
for line in \$(git log --oneline origin/master..HEAD)
do
  res=\$res\$(echo \$line | sed 's/(HEAD -> master)//g')'\n'
done
export IFS=''

res=\${res%??}

slackUser='$slackUser'
slackToken='$slackToken'
channelID='$channelID'
curl -H 'Content-type: application/json; charset=utf-8' \\
  -H 'Authorization: Bearer '\$slackToken'' 'https://slack.com/api/chat.postMessage' \\
  -d '{"channel": "'\$channelID'","text": ":git: '\$slackUser' pushed to $repo_name:\n'\$res'"}' > /dev/null 2>&1
EOF

chmod +x "$prepush_file"
echo "Installed $prepush_file (notifies as '$slackUser', repo '$repo_name')"
