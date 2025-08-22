ensure_directory() {
    local -r path="$1"
    local dir="$path"
    [[ -e "$path" || "$path" =~ \.[^.]+$ ]] && dir="$(dirname "$path")"
    [[ -d "$dir" ]] || mkdir -p "$dir"
}

ensure_command() {
    local -r cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Command '$cmd' not found. Please install it." >&2
        exit 1
    fi
}

ensure_symlink() {
    local target="$1"
    local link="$2"

    mkdir -p "$(dirname "$link")"

    if [ ! -L "$link" ] || [ "$(readlink "$link")" != "$target" ]; then
        ln -sf "$target" "$link"
    fi
}
