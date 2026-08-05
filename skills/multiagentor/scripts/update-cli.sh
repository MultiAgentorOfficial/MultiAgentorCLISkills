#!/bin/sh
set -eu

package=${MULTIAGENTOR_CLI_PACKAGE:-multiagentor-cli}
command -v npm >/dev/null 2>&1 || { echo 'npm is required to update MultiAgentor CLI.' >&2; exit 1; }
latest=$(npm view "$package@latest" version --json | tr -d '"[:space:]')
test -n "$latest" || { echo "Failed to resolve $package latest version from npm." >&2; exit 1; }
installed=$(npm list --global "$package" --depth=0 --json 2>/dev/null |
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{let j=JSON.parse(s);process.stdout.write(j.dependencies?.[process.argv[1]]?.version||"")}catch{}})' "$package" || true)
updated=false
if [ "$installed" != "$latest" ]; then
  npm install --global "$package@$latest" --no-audit --no-fund
  updated=true
fi
verified=$(npm list --global "$package" --depth=0 --json |
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{let j=JSON.parse(s);process.stdout.write(j.dependencies?.[process.argv[1]]?.version||"")})' "$package")
test "$verified" = "$latest" || { echo "CLI verification mismatch: installed $verified, expected $latest." >&2; exit 1; }
global_prefix=$(npm prefix --global)
invocation="$global_prefix/bin/multiagentor-cli"
if [ ! -x "$invocation" ]; then
  invocation=$(command -v multiagentor-cli || true)
fi
test -n "$invocation" && test -x "$invocation" || {
  echo "The npm package is installed, but its CLI shim was not found under $global_prefix/bin or PATH." >&2
  exit 1
}
"$invocation" --help >/dev/null
printf '{"previous_version":"%s","latest_version":"%s","installed_version":"%s","updated":%s,"invocation":"%s"}\n' \
  "$installed" "$latest" "$verified" "$updated" "$invocation"
