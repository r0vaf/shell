#!/usr/bin/env bash
# Pulls upstream caelestia-dots/shell changes into main, then merges main
# into rill-port. Never auto-resolves conflicts -- if one occurs, it stops
# and leaves you in the middle of the merge so you can fix it by hand.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

DOTFILES_REPO="${DOTFILES_REPO:-$HOME/src/river-rill-dotfiles}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree isn't clean. Commit or stash your changes first."
  exit 1
fi

echo "==> Fetching upstream"
git fetch upstream

echo "==> Fast-forwarding main"
git checkout main
git merge upstream/main --ff-only
git push origin main

echo "==> Merging main into rill-port"
git checkout rill-port
if ! git merge main --no-edit; then
  echo ""
  echo "CONFLICT -- resolve the files listed above by hand, then:"
  echo "  git add <resolved files>"
  echo "  git commit"
  echo "  git push origin rill-port"
  echo "Then re-run this script's dotfiles-bump step manually, or just"
  echo "re-run this whole script once rill-port is clean again."
  exit 1
fi
git push origin rill-port

NEW_COMMIT="$(git rev-parse HEAD)"
echo "==> rill-port now at $NEW_COMMIT"

if [[ -d "$DOTFILES_REPO/vendor/caelestia-shell" ]]; then
  echo "==> Bumping submodule pointer in river-rill-dotfiles"
  cd "$DOTFILES_REPO"
  git submodule update --remote vendor/caelestia-shell
  git add vendor/caelestia-shell
  git commit -m "Bump caelestia-shell submodule to $NEW_COMMIT"
  git push
else
  echo "WARNING: $DOTFILES_REPO/vendor/caelestia-shell not found -- skipped submodule bump."
fi

echo "==> Done. Remember: this only updates the repo. Rebuild/relaunch the"
echo "    shell separately to actually run the new code."
