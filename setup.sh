#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

install_prerequisites() {
    case "$(uname -s)" in
        Darwin)
            if ! command -v brew >/dev/null 2>&1; then
                echo "Homebrew is needed to install Python and Git. Install it from https://brew.sh, then rerun this command." >&2
                exit 1
            fi
            brew install python git
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y python3 python3-venv git
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3 git
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Sy --needed --noconfirm python git
            else
                echo "Install Python 3.9+ and Git with your Linux package manager, then rerun this command." >&2
                exit 1
            fi
            ;;
        *)
            echo "Unsupported shell host: $(uname -s)" >&2
            exit 1
            ;;
    esac
}

if ! command -v python3 >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
    install_prerequisites
fi

exec python3 "$ROOT/tools/bootstrap.py" "$@"
