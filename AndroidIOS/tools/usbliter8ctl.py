#!/usr/bin/env python3
"""Run upstream usbliter8ctl with libusb-package's cross-platform backend."""

from __future__ import annotations

import runpy
import sys
from pathlib import Path

import libusb_package
import usb.core


ROOT = Path(__file__).resolve().parents[1]
UPSTREAM_CTL = ROOT / "third_party" / "usbliter8-bootrom" / "usbliter8ctl"


def main() -> None:
    if not UPSTREAM_CTL.is_file():
        raise SystemExit("Run setup.ps1 or setup.sh first to fetch the pinned usbliter8 source.")

    # The upstream tool calls usb.core.find() without selecting a backend.
    # This wrapper routes discovery through libusb-package on Windows/macOS/Linux.
    find_device = usb.core.find
    backend = libusb_package.get_libusb1_backend()

    def find_with_libusb(*args, **kwargs):
        kwargs.setdefault("backend", backend)
        return find_device(*args, **kwargs)

    usb.core.find = find_with_libusb
    sys.argv[0] = str(UPSTREAM_CTL)
    runpy.run_path(str(UPSTREAM_CTL), run_name="__main__")


if __name__ == "__main__":
    main()
