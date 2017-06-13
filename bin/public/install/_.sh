
# === {{CMD}}  # Installs Crystal and Shards to /progs
install () {
  if [[ "$(arch)" != 'x86_64' ]]; then
    echo "!!! Only 64-bit architecures supported." >&2
    echo "   (Only 512 fibers allowed in 32-bit architectures.)" >&2
    exit 2
  fi

  case "$(lsb_release -r -c -s)" in
    "rolling void")
      PATH="$PATH:$THIS_DIR/../my_os/bin"
      my_os package --install libevent-devel gc gc-devel lzo-devel libmcrypt-devel libgcrypt-devel libressl-devel
      ;;
  esac

  install-crystal
} # === end function

get-output () {
  "$@" 2>/dev/null || :
}

get-latest () {
  lynx --dump "$1" | grep -P "releases/download.+x86.+" | tr -s ' ' | cut -d' ' -f3 | sort --version-sort | tail -n1
}

download () {
  local +x URL="$1"; shift
  local +x BASENAME="$(basename "$URL")"
  mkdir -p "$THIS_DIR/tmp/cache"

  cd "$THIS_DIR/tmp"
  if [[ -f cache/"$BASENAME" ]]; then
    echo "=== Using cache file: cache/$BASENAME" >&2
    cp -f "cache/$BASENAME" "$BASENAME"
  else
    echo "=== Downloading: $URL" >&2
    echo "" >&2
    curl -L "$URL" -o "$BASENAME"
    cp -f "$BASENAME" cache/"$BASENAME"
  fi
  echo "$PWD/$BASENAME"
}

install-crystal () {
  local +x NAME="Crystal"
  local +x EXEC_FILE="crystal"
  local +x URL="https://github.com/crystal-lang/crystal/releases"

  local +x STORAGE="$THIS_DIR/progs/$EXEC_FILE"
  local +x LATEST="$(get-latest "$URL")"
  local +x BASENAME="$(basename "$LATEST")"
  local +x VERSION="${BASENAME%$*-linux*}"
  local +x DIR="$STORAGE/versions/$VERSION"
  local +x LATEST_LINK="$THIS_DIR/progs/latest-$EXEC_FILE"

  if [[ -z "$LATEST" ]]; then
    echo "!!! Could not determine latest $NAME download on the Internet." >&2
    exit 2
  fi

  local +x CRYSTAL="$LATEST_LINK/bin/crystal"
  if [[ -x "$CRYSTAL" ]]; then
    local +x LATEST_VERSION="$(get-output "$CRYSTAL" --version)"

    if [[ ! -z "$LATEST_VERSION" && "$LATEST_VERSION" == "$(get-output "$DIR"/bin/crystal --version)" ]]; then
      echo "=== Already installed latest $NAME:" >&2
      echo "$DIR" >&2
      "$LATEST_LINK"/bin/crystal --version >&2
      return 0
    fi
  fi

  mkdir -p "$(dirname "$DIR")"
  mkdir -p "$THIS_DIR/tmp"

  local +x TMP_FILE="$(download "$LATEST")"

  cd "$(dirname "$DIR")"
  tar -zxf "$TMP_FILE"

  rm -f "$LATEST_LINK"
  ln -s "$DIR" "$LATEST_LINK"
  echo "=== Installed Crystal:" >&2
  "$LATEST_LINK"/bin/crystal --version >&2
} # === install-crystal

install-shards () {
  local +x NAME="Shards"
  local +x EXEC_FILE="shards"
  local +x URL="https://github.com/crystal-lang/shards/releases/latest"

  local +x STORAGE="$THIS_DIR/progs/$EXEC_FILE"
  local +x LATEST="$(get-latest "$URL")"
  local +x BASENAME="$(basename "$LATEST")"
  local +x VERSION="${BASENAME%$*_linux_*}"
  local +x DIR="$STORAGE/versions/$VERSION"
  local +x LATEST_LINK="$THIS_DIR/progs/latest-shards"

  if [[ -z "$LATEST" ]]; then
    echo "!!! Could not determine latest $NAME download on the Internet." >&2
    exit 2
  fi

  local +x LATEST_SHARDS="$(get-output "$LATEST_LINK/bin/shards" --version)"
  if [[ ! -z "$LATEST_SHARDS" && "$LATEST_SHARDS" == "$(get-output "$DIR"/bin/shards --version)" ]]; then
    echo "=== Already installed latest $NAME: " >&2
    echo "$DIR" >&2
    "$LATEST_LINK"/bin/shards --version >&2
    return 0
  fi

  # NOTE: The uncompressed file system will be just one file.
  #       So we create a directory for it and rename the file
  #       to "shards", keeping the version info in the shards-version/bin
  #       format:
  mkdir -p "$DIR"/bin

  local +x TMP_FILE="$(download "$LATEST")"

  cd "$(dirname "$TMP_FILE")"
  local +x BIN_FILE="$(basename "$BASENAME" .gz)"
  rm -f "$BIN_FILE"
  gunzip --decompress "$TMP_FILE"
  chmod +x "$BIN_FILE"
  mv "$BIN_FILE" "$DIR"/bin/shards

  cd "$THIS_DIR/progs"
  rm -f "$LATEST_LINK"
  ln -s "$DIR" "$LATEST_LINK"
  echo "=== Installed shards:" >&2
  "$LATEST_LINK"/bin/shards --version >&2
} # === install-shard

