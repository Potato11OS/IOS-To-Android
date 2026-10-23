#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
AOSP_ROOT="${1:-${ANDROID_BUILD_TOP:-}}"

if [[ "$(uname -s)" != Linux ]]; then
    echo "AOSP platform builds require Linux. On Windows, run this inside WSL2; native macOS AOSP builds are unsupported." >&2
    exit 2
fi

if [[ "$(uname -m)" != x86_64 ]]; then
    echo "AOSP platform builds require a 64-bit x86 Linux host." >&2
    exit 2
fi

if [[ -z "$AOSP_ROOT" ]]; then
    echo "Usage: $0 /path/to/aosp-workspace (or set ANDROID_BUILD_TOP)" >&2
    exit 2
fi

mkdir -p "$AOSP_ROOT"
if [[ -d "$AOSP_ROOT/.repo" ]]; then
    NEED_CHECKOUT=0
else
    if [[ -n "$(ls -A "$AOSP_ROOT")" ]]; then
        echo "AOSP workspace is not empty and has no .repo directory: $AOSP_ROOT" >&2
        echo "Choose an empty directory or an existing AOSP checkout." >&2
        exit 2
    fi
    NEED_CHECKOUT=1
fi

if [[ ! -r /proc/meminfo ]]; then
    echo "Cannot read Linux memory information; refusing to start an AOSP build without the resource check." >&2
    exit 2
fi

MEM_KB="$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)"
if [[ -z "$MEM_KB" || "$MEM_KB" -lt 62500000 ]]; then
    echo "AOSP build needs at least 64 GB RAM; this host reports $(( ${MEM_KB:-0} / 1024 / 1024 )) GiB." >&2
    exit 2
fi

FREE_KB="$(df -Pk "$AOSP_ROOT" | awk 'NR == 2 { print $4 }')"
if [[ "$NEED_CHECKOUT" -eq 1 ]]; then
    MIN_FREE_KB=390625000
    SPACE_NOTE="about 400 GB free for source checkout and build"
else
    MIN_FREE_KB=146484375
    SPACE_NOTE="about 150 GB free after checkout"
fi
if [[ -z "$FREE_KB" || "$FREE_KB" -lt "$MIN_FREE_KB" ]]; then
    echo "AOSP needs $SPACE_NOTE; the AOSP volume has $(( ${FREE_KB:-0} / 1024 / 1024 )) GiB free." >&2
    exit 2
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Automatic dependency installation currently supports Ubuntu/Debian (apt). Install the AOSP packages and Repo tool manually on this Linux distribution." >&2
    exit 2
fi

if [[ "$(id -u)" -eq 0 ]]; then
    APT_COMMAND=(apt-get)
else
    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required to install AOSP build dependencies." >&2
        exit 2
    fi
    APT_COMMAND=(sudo apt-get)
fi

"${APT_COMMAND[@]}" update
"${APT_COMMAND[@]}" install -y \
    git-core gnupg flex bison build-essential zip curl zlib1g-dev \
    libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev \
    libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 repo

if ! command -v repo >/dev/null 2>&1; then
    echo "The AOSP Repo launcher was not installed. Install repo with apt and rerun." >&2
    exit 2
fi

if [[ "$NEED_CHECKOUT" -eq 1 ]]; then
    cd "$AOSP_ROOT"
    repo init --partial-clone --no-use-superproject \
        -b android-latest-release \
        -u https://android.googlesource.com/platform/manifest
fi

cd "$AOSP_ROOT"
repo sync -c -j8

if [[ ! -f "$AOSP_ROOT/build/envsetup.sh" ]]; then
    echo "AOSP sync completed without build/envsetup.sh; inspect the checkout before retrying." >&2
    exit 2
fi

DEST="$AOSP_ROOT/device/apple/iphone11"
SOURCE="$ROOT/android/device/apple/iphone11"
if [[ -e "$DEST" ]]; then
    if ! diff -qr "$SOURCE" "$DEST" >/dev/null; then
        echo "AOSP target directory already exists and differs from this project: $DEST" >&2
        echo "Review or merge the target files manually, then rerun." >&2
        exit 2
    fi
    echo "AOSP target already staged: $DEST"
else
    mkdir -p "$(dirname "$DEST")"
    cp -R "$SOURCE" "$DEST"
fi

cd "$AOSP_ROOT"
source build/envsetup.sh
lunch aosp_iphone11_userspace aosp_current userdebug
m systemimage

echo "Android userspace image built under $AOSP_ROOT/out/target/product/iphone11/system.img"
echo "This is not a bootable or flashable iPhone image."
