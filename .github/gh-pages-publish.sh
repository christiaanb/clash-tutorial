#!/usr/bin/env bash
#
# The one thing in this repository that writes to the gh-pages branch.
#
#   gh-pages-publish.sh book/book ''       publish main's book at the root
#   gh-pages-publish.sh book/book pr/7     publish a pull request preview
#   gh-pages-publish.sh '' pr/7            remove a pull request preview
#
# The branch holds nothing that is authored by hand, but it does hold more than
# one thing at a time: main's rendered book at the root, and a rendered book per
# open pull request under pr/. That is why this is a script rather than
# peaceiris/actions-gh-pages with force_orphan, which replaced the whole branch on
# every push to main and so would delete every open preview each time a chapter
# merged. What gets deleted is the decision this file exists to make explicit.
#
# Reads GITHUB_TOKEN, GITHUB_REPOSITORY and GITHUB_SHA from the environment.

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <directory-to-publish-or-empty> <destination-in-branch-or-empty>" >&2
  exit 2
fi

src=$1
dest=$2

: "${GITHUB_TOKEN:?must be set: the token this pushes with}"
: "${GITHUB_REPOSITORY:?must be set: owner/name of the repository to push to}"
: "${GITHUB_SHA:?must be set: the commit being published, named in the commit message}"

# A destination is a path inside the branch and nothing else. Rejected rather
# than sanitised, because the only caller that supplies one interpolates a pull
# request number into it.
case $dest in
  /* | *..* | *' '*)
    echo "refusing to publish to '$dest': not a plain relative path" >&2
    exit 2
    ;;
esac

if [ -n "$src" ] && [ ! -d "$src" ]; then
  echo "there is nothing to publish: $src is not a directory" >&2
  exit 1
fi

# Resolved before anything changes directory, since the source is given relative
# to the working directory the job runs in.
src_abs=
if [ -n "$src" ]; then
  src_abs=$(cd "$src" && pwd)
fi

remote="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Two runs can reach this at once — a merge to main and a push to an open pull
# request both publish — so a push can be rejected as non-fast-forward through no
# fault of its own. The jobs share a concurrency group to make that rare; this
# loop is what makes it harmless. Each attempt starts from a fresh clone, because
# what the previous attempt was rejected for is precisely a tip it had not seen.
attempts=3
attempt=1
while :; do
  rm -rf "${work:?}/gh-pages"

  set +e
  git ls-remote --exit-code --heads "$remote" gh-pages >/dev/null 2>&1
  branch_state=$?
  set -e

  case $branch_state in
    0)
      # Only the tip is needed: nothing here reads the history it is adding to.
      git clone --quiet --depth 1 --branch gh-pages "$remote" "$work/gh-pages"
      ;;
    2)
      if [ -z "$src" ]; then
        echo "There is no gh-pages branch, so there is no $dest to remove."
        exit 0
      fi
      echo "There is no gh-pages branch yet. Starting one."
      git init --quiet -b gh-pages "$work/gh-pages"
      git -C "$work/gh-pages" remote add origin "$remote"
      ;;
    *)
      echo "cannot reach ${GITHUB_REPOSITORY}: git ls-remote failed" >&2
      exit 1
      ;;
  esac

  cd "$work/gh-pages"

  git config user.name "clash-tutorial CI"
  git config user.email "actions@github.com"

  if [ -z "$dest" ]; then
    # Everything at the root is replaced, so that a page dropped from SUMMARY.md
    # stops being served. Everything except pr/, which belongs to the pull
    # requests that are open right now and not to the commit being published.
    find . -mindepth 1 -maxdepth 1 ! -name .git ! -name pr -exec rm -rf {} +
    target=.
  else
    rm -rf "./${dest:?}"
    target=$dest
  fi

  if [ -n "$src_abs" ]; then
    mkdir -p "$target"
    cp -R "$src_abs/." "$target/"
  fi

  # mdBook writes a .nojekyll into its own output, which lands at the root only
  # when main publishes. Jekyll is switched off by the root of the branch and
  # nowhere else, so a preview published before main has ever published would be
  # served through Jekyll without this line.
  touch .nojekyll

  git add -A
  # Redirected because --quiet still prints a header for a file whose content is
  # empty, such as the .nojekyll above. Only the exit status is wanted.
  if git diff --cached --quiet >/dev/null; then
    echo "gh-pages already holds this. Nothing to push."
    exit 0
  fi

  if [ -n "$src" ]; then
    git commit --quiet -m "Publish ${dest:-the book} from ${GITHUB_REPOSITORY}@${GITHUB_SHA}"
  else
    git commit --quiet -m "Remove ${dest} from ${GITHUB_REPOSITORY}@${GITHUB_SHA}"
  fi

  if git push --quiet origin gh-pages; then
    echo "Pushed to gh-pages."
    exit 0
  fi

  if [ "$attempt" -ge "$attempts" ]; then
    echo "gh-pages was updated underneath this job $attempts times running. Giving up." >&2
    exit 1
  fi
  echo "gh-pages moved while this job was working. Retrying."
  attempt=$((attempt + 1))
  cd "$work"
done
