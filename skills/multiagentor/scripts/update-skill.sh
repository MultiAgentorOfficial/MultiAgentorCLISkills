#!/bin/sh
set -eu

repository=${MULTIAGENTOR_SKILL_REPOSITORY:-MultiAgentorOfficial/MultiAgentorCLISkills}
ref=${MULTIAGENTOR_SKILL_REF:-main}
check_only=false
if [ "${1:-}" = "--check-only" ]; then check_only=true; fi

skill_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version_file="$skill_root/VERSION"
integrity_ok=true
for required in SKILL.md VERSION agents/openai.yaml references/command-reference.md scripts/update-skill.ps1 scripts/update-skill.sh; do
  if [ ! -f "$skill_root/$required" ]; then integrity_ok=false; fi
done
if [ -f "$skill_root/SKILL.md" ] && ! grep -Eq '^name:[[:space:]]*multiagentor[[:space:]]*$' "$skill_root/SKILL.md"; then
  integrity_ok=false
fi
if [ -f "$version_file" ]; then current=$(tr -d '[:space:]' < "$version_file"); else current=0.0.0; integrity_ok=false; fi

validate_version() {
  printf '%s' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' || {
    echo "Invalid skill version: $1" >&2
    exit 1
  }
}

version_ge() {
  awk -v left="$1" -v right="$2" 'BEGIN {
    split(left, a, "."); split(right, b, ".");
    for (i = 1; i <= 3; i++) {
      if ((a[i] + 0) > (b[i] + 0)) exit 0;
      if ((a[i] + 0) < (b[i] + 0)) exit 1;
    }
    exit 0;
  }'
}

emit_result() {
  printf '{"current_version":"%s","latest_version":"%s","integrity_ok":%s,"updated":%s,"method":"%s","backup_path":"%s","restart_required":%s}\n' \
    "$1" "$2" "$3" "$4" "$5" "$6" "$4"
}

if ! printf '%s' "$current" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'; then
  current=0.0.0
  integrity_ok=false
fi
latest=$(curl --fail --silent --show-error --location --retry 3 \
  "https://raw.githubusercontent.com/$repository/$ref/skills/multiagentor/VERSION" | tr -d '[:space:]')
validate_version "$latest"

if version_ge "$current" "$latest" && [ "$integrity_ok" = true ]; then
  emit_result "$current" "$latest" true false none ""
  exit 0
fi
if [ "$check_only" = true ]; then
  emit_result "$current" "$latest" "$integrity_ok" false available-or-repair ""
  exit 0
fi

if command -v git >/dev/null 2>&1 && worktree=$(git -C "$skill_root" rev-parse --show-toplevel 2>/dev/null); then
  origin=$(git -C "$worktree" remote get-url origin)
  case "$origin" in
    https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills|https://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git|git@github.com:MultiAgentorOfficial/MultiAgentorCLISkills|git@github.com:MultiAgentorOfficial/MultiAgentorCLISkills.git|ssh://git@github.com/MultiAgentorOfficial/MultiAgentorCLISkills|ssh://git@github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git|git://github.com/MultiAgentorOfficial/MultiAgentorCLISkills|git://github.com/MultiAgentorOfficial/MultiAgentorCLISkills.git) ;;
    *) echo "A Skill update or repair is required, but this Git worktree origin is not the official repository: $origin" >&2; exit 1 ;;
  esac
  test -z "$(git -C "$worktree" status --porcelain)" || {
    echo "A Skill update or repair is required, but the Git worktree has local changes: $worktree" >&2
    exit 1
  }
  git -C "$worktree" pull --ff-only origin "$ref"
  installed=$(tr -d '[:space:]' < "$version_file")
  validate_version "$installed"
  version_ge "$installed" "$latest" || {
    echo "Git pull completed but VERSION is still $installed (expected at least $latest)." >&2
    exit 1
  }
  emit_result "$current" "$installed" true true git-ff-only ""
  exit 0
fi

parent=$(dirname "$skill_root")
stamp=$(date +%Y%m%d%H%M%S)
temporary=$(mktemp -d "$parent/.multiagentor-update-$stamp-XXXXXX")
staged=$(mktemp -d "$parent/.multiagentor-staged-$stamp-XXXXXX")
rmdir "$staged"
backup="$parent/multiagentor.backup-$current-$stamp"
cleanup() {
  rm -rf "$temporary"
  if [ -d "$staged" ]; then rm -rf "$staged"; fi
}
trap cleanup EXIT HUP INT TERM

archive="$temporary/repository.zip"
curl --fail --silent --show-error --location --retry 3 \
  "https://github.com/$repository/archive/refs/heads/$ref.zip" -o "$archive"
mkdir "$temporary/extract"
if command -v ditto >/dev/null 2>&1; then
  ditto -x -k "$archive" "$temporary/extract"
else
  unzip -q "$archive" -d "$temporary/extract"
fi
source=$(find "$temporary/extract" -type f -path '*/skills/multiagentor/SKILL.md' -print -quit)
test -n "$source" || { echo 'Downloaded archive does not contain skills/multiagentor/SKILL.md.' >&2; exit 1; }
source=$(dirname "$source")
archive_version=$(tr -d '[:space:]' < "$source/VERSION")
validate_version "$archive_version"
version_ge "$archive_version" "$latest" || {
  echo "Archive version $archive_version is older than advertised $latest." >&2
  exit 1
}
grep -Eq '^name:[[:space:]]*multiagentor[[:space:]]*$' "$source/SKILL.md" || {
  echo 'Downloaded skill identity validation failed.' >&2
  exit 1
}
cp -R "$source" "$staged"
mv "$skill_root" "$backup"
if ! mv "$staged" "$skill_root"; then
  test -e "$skill_root" || mv "$backup" "$skill_root"
  exit 1
fi
emit_result "$current" "$archive_version" true true github-archive "$backup"
