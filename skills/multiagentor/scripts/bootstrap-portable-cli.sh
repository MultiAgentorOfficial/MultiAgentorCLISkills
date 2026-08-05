#!/bin/sh
set -eu

NODE_INDEX_URL=${NODE_INDEX_URL:-https://nodejs.org/dist/index.json}
NODE_DIST_BASE_URL=${NODE_DIST_BASE_URL:-https://nodejs.org/dist}
CLI_PACKAGE=${CLI_PACKAGE:-multiagentor-cli@latest}

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This portable bootstrap supports macOS only; detected $(uname -s)." >&2
  exit 1
fi

machine=$(uname -m)
if [ "$machine" != "arm64" ]; then
  echo "Unsupported macOS architecture: $machine. The current MultiAgentor npm package supports Apple Silicon (darwin-arm64) only." >&2
  exit 1
fi

data_root=${MULTIAGENTOR_HOME:-"$HOME/Library/Application Support/multiagentor"}
cache_root=${CACHE_ROOT:-"$data_root/portable-runtime"}
platform=darwin-arm64
mkdir -p "$cache_root"

index_file=$(mktemp "$cache_root/.node-index.XXXXXX")
cleanup() {
  rm -f "$index_file"
  if [ "${temporary_dir:-}" != "" ] && [ -d "$temporary_dir" ]; then
    case "$temporary_dir" in
      "$cache_root"/.bootstrap-*) rm -rf "$temporary_dir" ;;
    esac
  fi
}
trap cleanup EXIT HUP INT TERM

curl --fail --silent --show-error --location --retry 3 "$NODE_INDEX_URL" -o "$index_file"
release_line=$(grep '"lts":' "$index_file" | grep '"darwin-arm64"' | head -n 1 || true)
version=$(printf '%s\n' "$release_line" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
major=$(printf '%s\n' "$version" | sed -n 's/^v\([0-9][0-9]*\).*/\1/p')
if [ "$version" = "" ] || [ "$major" = "" ] || [ "$major" -lt 18 ]; then
  echo "No compatible Node.js LTS >=18 release with a darwin-arm64 archive was found." >&2
  exit 1
fi

archive_name="node-$version-$platform.tar.gz"
node_dir="$cache_root/node-$version-$platform"
node_bin="$node_dir/bin/node"
npm_bin="$node_dir/bin/npm"
node_downloaded=false

if [ ! -x "$node_bin" ] || [ ! -x "$npm_bin" ]; then
  temporary_dir=$(mktemp -d "$cache_root/.bootstrap-XXXXXX")
  archive="$temporary_dir/$archive_name"
  checksums="$temporary_dir/SHASUMS256.txt"
  release_base="${NODE_DIST_BASE_URL%/}/$version"
  curl --fail --silent --show-error --location --retry 3 "$release_base/SHASUMS256.txt" -o "$checksums"
  curl --fail --silent --show-error --location --retry 3 "$release_base/$archive_name" -o "$archive"
  expected=$(awk -v file="$archive_name" '$2 == file { print $1; exit }' "$checksums")
  if [ "$expected" = "" ]; then
    echo "The official checksum list does not contain $archive_name." >&2
    exit 1
  fi
  actual=$(shasum -a 256 "$archive" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then
    echo "SHA-256 verification failed for $archive_name." >&2
    exit 1
  fi
  tar -xzf "$archive" -C "$temporary_dir"
  extracted="$temporary_dir/node-$version-$platform"
  if [ ! -x "$extracted/bin/node" ]; then
    echo "The downloaded Node.js archive is incomplete." >&2
    exit 1
  fi
  if [ ! -d "$node_dir" ]; then
    mv "$extracted" "$node_dir"
  fi
  node_downloaded=true
fi

cli_root="$cache_root/cli"
cli_command="$cli_root/node_modules/.bin/multiagentor-cli"
launcher="$cache_root/multiagentor-cli-portable"
PATH="$node_dir/bin:$PATH"
export PATH

package_json="$cli_root/node_modules/multiagentor-cli/package.json"
installed_cli_version=""
if [ -f "$package_json" ]; then
  installed_cli_version=$("$node_bin" -e 'process.stdout.write(require(process.argv[1]).version)' "$package_json")
fi
latest_cli_version=""
if [ "$CLI_PACKAGE" = "multiagentor-cli@latest" ]; then
  latest_cli_version=$("$npm_bin" view multiagentor-cli@latest version --json | tr -d '"[:space:]')
  test -n "$latest_cli_version" || { echo 'Failed to resolve the latest MultiAgentor CLI version from npm.' >&2; exit 1; }
fi
if [ ! -x "$cli_command" ] || { [ -n "$latest_cli_version" ] && [ "$installed_cli_version" != "$latest_cli_version" ]; }; then
  install_target=$CLI_PACKAGE
  if [ -n "$latest_cli_version" ]; then install_target="multiagentor-cli@$latest_cli_version"; fi
  "$npm_bin" install --prefix "$cli_root" --no-audit --no-fund "$install_target"
fi
if [ ! -x "$cli_command" ]; then
  echo "The npm package did not create the expected CLI command: $cli_command" >&2
  exit 1
fi
"$cli_command" --help >/dev/null
verified_cli_version=$("$node_bin" -e 'process.stdout.write(require(process.argv[1]).version)' "$package_json")
if [ -n "$latest_cli_version" ] && [ "$verified_cli_version" != "$latest_cli_version" ]; then
  echo "CLI verification mismatch: installed $verified_cli_version, expected $latest_cli_version." >&2
  exit 1
fi
cli_updated=false
if [ -n "$installed_cli_version" ] && [ "$installed_cli_version" != "$verified_cli_version" ]; then cli_updated=true; fi

escaped_node_dir=$(printf '%s' "$node_dir/bin" | sed "s/'/'\\\\''/g")
escaped_cli=$(printf '%s' "$cli_command" | sed "s/'/'\\\\''/g")
{
  printf '%s\n' '#!/bin/sh'
  printf "PATH='%s':\$PATH\n" "$escaped_node_dir"
  printf '%s\n' 'export PATH'
  printf "exec '%s' \"\$@\"\n" "$escaped_cli"
} > "$launcher"
chmod 755 "$launcher"

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

printf '{"invocation":"%s","node_path":"%s","npm_path":"%s","node_version":"%s","platform":"%s","cache_root":"%s","node_downloaded":%s,"cli_version":"%s","latest_cli_version":"%s","cli_updated":%s}\n' \
  "$(json_escape "$launcher")" \
  "$(json_escape "$node_bin")" \
  "$(json_escape "$npm_bin")" \
  "$(json_escape "$("$node_bin" --version)")" \
  "$platform" \
  "$(json_escape "$cache_root")" \
  "$node_downloaded" \
  "$verified_cli_version" \
  "$latest_cli_version" \
  "$cli_updated"
