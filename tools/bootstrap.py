#!/usr/bin/env python3
"""Prepare host-side tooling for the Android-on-iPhone research project."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VENV = ROOT / ".venv"
BOOTROM_REPO = ROOT / "third_party" / "usbliter8-bootrom"
BOOTROM_URL = "https://github.com/JoshAtticus/usbliter8.git"
BOOTROM_COMMIT = "479dbbf4ad80e4a454e0779d1b4d1ec5eb0d7bd5"
REQUIREMENTS = ROOT / "requirements-host.txt"

FIRMWARE_ASSETS = {
    "pico2": "usbliter8.pico2.uf2",
    "pimoroni_tiny2350": "usbliter8.pimoroni_tiny2350.uf2",
    "waveshare_rp2350_usb_a": "usbliter8.waveshare_rp2350_usb_a.uf2",
    "waveshare_rp2350_zero": "usbliter8.waveshare_rp2350_zero.uf2",
}
FIRMWARE_RELEASE = "https://github.com/JoshAtticus/usbliter8/releases/download/rp2350"


def run(command: list[str], *, cwd: Path | None = None) -> None:
    print("+", subprocess.list2cmdline(command))
    subprocess.run(command, cwd=cwd, check=True)


def venv_python() -> Path:
    if os.name == "nt":
        return VENV / "Scripts" / "python.exe"
    return VENV / "bin" / "python"


def setup_python_environment() -> None:
    if sys.version_info < (3, 9):
        raise RuntimeError("Python 3.9 or newer is required; found " + sys.version.split()[0])

    if not VENV.exists():
        run([sys.executable, "-m", "venv", str(VENV)])

    python = venv_python()
    if not python.exists():
        raise RuntimeError(f"The virtual environment was not created at {VENV}")

    run([str(python), "-m", "pip", "install", "-r", str(REQUIREMENTS)])


def pin_bootrom_checkout() -> None:
    git = shutil.which("git")
    if not git:
        raise RuntimeError("Git is required to fetch the pinned usbliter8 dependency")

    if BOOTROM_REPO.exists():
        result = subprocess.run(
            [git, "-C", str(BOOTROM_REPO), "rev-parse", "HEAD"],
            text=True,
            capture_output=True,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"{BOOTROM_REPO} already exists but is not a Git checkout; move it aside and rerun setup"
            )
        current = result.stdout.strip().lower()
        if current != BOOTROM_COMMIT:
            raise RuntimeError(
                f"usbliter8 checkout is {current}, expected pinned commit {BOOTROM_COMMIT}; "
                "setup left the existing checkout untouched"
            )
    else:
        BOOTROM_REPO.parent.mkdir(parents=True, exist_ok=True)
        run([git, "init", str(BOOTROM_REPO)])
        run([git, "-C", str(BOOTROM_REPO), "remote", "add", "origin", BOOTROM_URL])
        run([git, "-C", str(BOOTROM_REPO), "fetch", "--depth", "1", "origin", BOOTROM_COMMIT])
        run([git, "-C", str(BOOTROM_REPO), "checkout", "--detach", "FETCH_HEAD"])

    if not (BOOTROM_REPO / "README.md").is_file() or not (BOOTROM_REPO / "usbliter8ctl").is_file():
        raise RuntimeError("The pinned usbliter8 checkout is missing expected source files")


def download_firmware(board: str) -> Path:
    asset = FIRMWARE_ASSETS[board]
    url = f"{FIRMWARE_RELEASE}/{asset}"
    destination_dir = ROOT / ".build" / "firmware"
    destination_dir.mkdir(parents=True, exist_ok=True)
    destination = destination_dir / asset

    if destination.exists():
        raise RuntimeError(f"Refusing to overwrite existing firmware file: {destination}")

    request = urllib.request.Request(url, headers={"User-Agent": "AndroidIOS-bootstrap"})
    digest = hashlib.sha256()
    total = 0
    temporary_name = None
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            with tempfile.NamedTemporaryFile(
                mode="wb", prefix=asset + ".", suffix=".part", dir=destination_dir, delete=False
            ) as temporary:
                temporary_name = temporary.name
                while True:
                    chunk = response.read(1024 * 1024)
                    if not chunk:
                        break
                    total += len(chunk)
                    digest.update(chunk)
                    temporary.write(chunk)

        if total < 1024:
            raise RuntimeError(f"Downloaded firmware is unexpectedly small ({total} bytes)")

        os.replace(temporary_name, destination)
        temporary_name = None
    finally:
        if temporary_name and os.path.exists(temporary_name):
            os.unlink(temporary_name)

    print(f"Downloaded {asset} ({total:,} bytes, SHA-256 {digest.hexdigest()})")
    return destination


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare host tools and optional RP2350 firmware")
    parser.add_argument(
        "--board",
        choices=sorted(FIRMWARE_ASSETS),
        help="download the official usbliter8 UF2 for this RP2350 board",
    )
    args = parser.parse_args()

    setup_python_environment()
    pin_bootrom_checkout()
    if args.board:
        firmware = download_firmware(args.board)
        print(f"UF2 ready to flash manually in the board's BOOTSEL mode: {firmware}")

    print("Host setup complete.")
    print("No iPhone was accessed or modified by this setup command.")
    print("Android boot/install is not available yet: this project has no reproducible T8030 Android kernel, DTB, or Android image.")
    if not args.board:
        print("To also download a UF2, rerun setup with --board and your RP2350 board name.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"Setup failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
