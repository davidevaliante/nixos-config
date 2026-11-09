# Clone or fully update the games listed below, each on its branch, and report what changed.
#
# Usage:
#   tg-sync-games [game ...] [--dir=<games-root>] [--force]
#
#   No game names  -> sync every game in GAMES.
#   game names     -> sync only those (must be listed in GAMES).
#
# Each game is placed in <games-root>/<name>
# (default games-root: $TG_GAMES_DIR, else ~/topgaming/frontend/games).
# If local uncommitted changes or unpushed commits would be lost, that game is skipped
# unless --force is given (then they are discarded: reset --hard + clean -fd, ignored files kept).

# ======================= EDIT HERE =======================
REPO_ROOT="ssh://git-codecommit.eu-central-1.amazonaws.com/v1/repos"

# <repo name>  <branch>
GAMES=(
  "fe_book-of-tomes  development"
  "lam2  development"
  "owl-kingdom-2  development"
  "ofg2  development"
  "yingyang  development"
  "bod  development"
  "fe_candy_wins  development"
  "fe_fruit_mash  development"
  "ger  development"
  "bourbonspin  development"
  "fe_tight_lines  development"
  "dgr  development"
  "boa  development"
  "rth  development"
  "gdm  development"
  "MLC  development"
  "toc  development"
  "gyo-fe  development"
  "voe  development"
  "sfg  development"
  "snw  development"
  "waf  development"
  "ror  development"
  "pzs  development"
  "sph  development"
  "dtc  development"
  "bt6  development"
  "aob  development"
  "drr  development"
  "tlh  development"
  "ker  development"
  "goa  development"
  "cod  development"
)
# =========================================================

set -euo pipefail

usage() {
  cat <<'USAGE'
Clone or fully update the games listed in GAMES, each on its branch, and report what changed.

Usage:
  tg-sync-games [game ...] [--dir=<games-root>] [--force]

  No game names  -> sync every game in GAMES.
  game names     -> sync only those (must be listed in GAMES).

Each game is placed in <games-root>/<name>
(default games-root: $TG_GAMES_DIR, else ~/topgaming/frontend/games).
If local uncommitted changes or unpushed commits would be lost, that game is skipped
unless --force is given (then they are discarded: reset --hard + clean -fd, ignored files kept).
USAGE
  exit "${1:-0}"
}

ROOT_DIR="${TG_GAMES_DIR:-$HOME/topgaming/frontend/games}"
FORCE=0
SELECTED=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir=*) ROOT_DIR="${1#*=}" ;;
    --dir) ROOT_DIR="${2:?--dir needs a value}"; shift ;;
    --force|-f) FORCE=1 ;;
    -h|--help) usage 0 ;;
    -*) echo "Unknown option: $1" >&2; usage 1 ;;
    *) SELECTED+=("$1") ;;
  esac
  shift
done

if [[ -t 1 ]]; then
  B=$'\e[1m'; G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; C=$'\e[36m'; N=$'\e[0m'
else
  B=""; G=""; Y=""; R=""; C=""; N=""
fi
info() { echo "${C}==>${N} $*"; }
warn() { echo "${Y}warning:${N} $*" >&2; }
die()  { echo "${R}error:${N} $*" >&2; exit 1; }
indent() { sed 's/^/  /'; }

update_extras() {
  # Submodules and LFS objects, if the repo uses them.
  if [[ -f "$TARGET/.gitmodules" ]]; then
    info "Updating submodules"
    git -C "$TARGET" submodule sync --recursive >/dev/null
    git -C "$TARGET" submodule update --init --recursive
  fi
  if grep -qs 'filter=lfs' "$TARGET/.gitattributes" && git lfs version >/dev/null 2>&1; then
    info "Pulling LFS objects"
    git -C "$TARGET" lfs pull
  fi
}

# Runs in a subshell per game, so `die`/`exit` only end that game.
sync_game() {
  NAME="$1"
  BRANCH="$2"
  REPO_URL="$REPO_ROOT/$NAME"
  TARGET="$ROOT_DIR/$NAME"

  # -------------------------------------------------------------- fresh clone
  if [[ ! -e "$TARGET" ]]; then
    info "Cloning ${B}$NAME${N} ($BRANCH) into $TARGET"
    git clone --branch "$BRANCH" "$REPO_URL" "$TARGET"
    update_extras
    FILES="$(git -C "$TARGET" ls-files | wc -l | tr -d ' ')"
    SIZE="$(du -sh --exclude=.git "$TARGET" 2>/dev/null | cut -f1)"
    echo
    echo "${B}${G}Downloaded $NAME from scratch${N}"
    echo "  branch : $BRANCH"
    echo "  commit : $(git -C "$TARGET" log -1 --format='%h %s (%an, %ar)')"
    echo "  files  : $FILES tracked${SIZE:+, $SIZE on disk}"
    exit 0
  fi

  # -------------------------------------------------------------- update
  [[ -d "$TARGET/.git" ]] || die "$TARGET exists but is not a git repository"

  CURRENT_URL="$(git -C "$TARGET" remote get-url origin 2>/dev/null || true)"
  if [[ "$CURRENT_URL" != "$REPO_URL" ]]; then
    [[ $FORCE -eq 1 ]] || die "$TARGET has origin '$CURRENT_URL', not '$REPO_URL' (use --force to repoint it)"
    warn "repointing origin from '$CURRENT_URL' to '$REPO_URL'"
    git -C "$TARGET" remote set-url origin "$REPO_URL"
  fi

  OLD_BRANCH="$(git -C "$TARGET" branch --show-current)"
  OLD_SHA="$(git -C "$TARGET" rev-parse HEAD 2>/dev/null || true)"

  info "Fetching ${B}$NAME${N} ($BRANCH)"
  git -C "$TARGET" fetch --prune origin \
    "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" \
    || die "could not fetch branch '$BRANCH' from origin"
  NEW_SHA="$(git -C "$TARGET" rev-parse "origin/$BRANCH")"

  # Safety checks: anything that a hard reset would throw away.
  DIRTY="$(git -C "$TARGET" status --porcelain)"
  UNPUSHED=""
  if git -C "$TARGET" rev-parse -q --verify "refs/heads/$BRANCH" >/dev/null; then
    UNPUSHED="$(git -C "$TARGET" log --oneline "origin/$BRANCH..refs/heads/$BRANCH")"
  fi
  if [[ -n "$DIRTY" || -n "$UNPUSHED" ]]; then
    [[ -n "$DIRTY" ]]    && { echo "${Y}Local changes:${N}";              indent <<<"$DIRTY"; }
    [[ -n "$UNPUSHED" ]] && { echo "${Y}Local commits not on origin/$BRANCH:${N}"; indent <<<"$UNPUSHED"; }
    [[ $FORCE -eq 1 ]] || die "refusing to overwrite local work in $TARGET (re-run with --force to discard it)"
    warn "--force given: discarding the above"
  fi

  git -C "$TARGET" checkout -q -B "$BRANCH" "origin/$BRANCH"
  git -C "$TARGET" reset -q --hard "origin/$BRANCH"
  git -C "$TARGET" clean -q -fd
  git -C "$TARGET" branch -q --set-upstream-to="origin/$BRANCH" "$BRANCH"
  update_extras

  # -------------------------------------------------------------- report
  echo
  if [[ "$OLD_BRANCH" != "$BRANCH" ]]; then
    echo "${B}Switched branch:${N} ${OLD_BRANCH:-<detached>} -> $BRANCH"
  fi

  if [[ "$OLD_SHA" == "$NEW_SHA" ]]; then
    echo "${B}${G}$NAME is already up to date${N} on $BRANCH at $(git -C "$TARGET" log -1 --format='%h %s (%ar)')"
    exit 0
  fi

  echo "${B}${G}Updated $NAME${N}  ${OLD_SHA:0:9} -> ${NEW_SHA:0:9}  ($BRANCH)"

  if git -C "$TARGET" merge-base --is-ancestor "$OLD_SHA" "$NEW_SHA" 2>/dev/null; then
    COUNT="$(git -C "$TARGET" rev-list --count "$OLD_SHA..$NEW_SHA")"
    echo
    echo "${B}New commits ($COUNT):${N}"
    git -C "$TARGET" log --no-merges --format='  %h %s (%an, %ar)' "$OLD_SHA..$NEW_SHA"
  else
    echo
    echo "${Y}History is not linear from the previous state (branch switch or force-push);${N}"
    echo "${Y}showing the file diff between the old and new checkout.${N}"
  fi

  echo
  echo "${B}Files changed:${N}"
  git -C "$TARGET" diff --name-status -M "$OLD_SHA" "$NEW_SHA" | awk -v g="$G" -v r="$R" -v y="$Y" -v n="$N" '
    { s = substr($1, 1, 1) }
    s == "A" { printf "  %sadded%s    %s\n", g, n, $2; next }
    s == "D" { printf "  %sdeleted%s  %s\n", r, n, $2; next }
    s == "R" { printf "  %srenamed%s  %s -> %s\n", y, n, $2, $3; next }
    { printf "  %smodified%s %s\n", y, n, $2 }'
  echo
  echo "  $(git -C "$TARGET" diff --shortstat "$OLD_SHA" "$NEW_SHA")"
}

# ---------------------------------------------------------------- main
declare -A BRANCH_OF=()
ORDER=()
for entry in "${GAMES[@]}"; do
  read -r name branch <<<"$entry"
  [[ -n "${name:-}" && -n "${branch:-}" ]] || die "bad GAMES entry: '$entry' (expected '<name> <branch>')"
  BRANCH_OF[$name]="$branch"
  ORDER+=("$name")
done

if [[ ${#SELECTED[@]} -gt 0 ]]; then
  for name in "${SELECTED[@]}"; do
    [[ -n "${BRANCH_OF[$name]:-}" ]] || die "'$name' is not in GAMES (known: ${ORDER[*]})"
  done
  ORDER=("${SELECTED[@]}")
fi

FAILED=()
for name in "${ORDER[@]}"; do
  echo
  echo "${B}━━━━━━━━━━ $name (${BRANCH_OF[$name]}) ━━━━━━━━━━${N}"
  ( sync_game "$name" "${BRANCH_OF[$name]}" ) || FAILED+=("$name")
done

echo
if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "${R}${B}Failed: ${FAILED[*]}${N}"
  exit 1
fi
echo "${G}${B}All ${#ORDER[@]} game(s) synced.${N}"
