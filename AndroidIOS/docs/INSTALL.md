# Host setup

The setup command prepares the host tools used by the current research stage. Run it from a fresh project checkout:

```powershell
.\setup.ps1
```

On Linux or macOS:

```sh
./setup.sh
```

The scripts create a project-local Python environment, install the pinned patchfinder and USB-control Python dependencies, and fetch the pinned usbliter8 BootROM source into `third_party/usbliter8-bootrom`. The BootROM source has no license file in its upstream repository, so the setup fetches it as a local dependency instead of copying it into the tracked project source. Firmware is downloaded from the upstream RP2350 release when `--board` is supplied, so the default setup does not need the Pico SDK, CMake, or ARM cross-compiler.

The cross-platform wrapper for the upstream USB control program is available after setup:

```powershell
.\.venv\Scripts\python.exe tools\usbliter8ctl.py --help
```

```sh
.venv/bin/python tools/usbliter8ctl.py --help
```

To also download the official RP2350 firmware for a board:

```powershell
.\setup.ps1 --board pico2
```

```sh
./setup.sh --board waveshare_rp2350_usb_a
```

Supported board names are `pico2`, `pimoroni_tiny2350`, `waveshare_rp2350_usb_a`, and `waveshare_rp2350_zero`. The downloaded UF2 is saved under `.build/firmware/`; flashing it to a board remains a manual BOOTSEL file-copy step.

## What this does not do yet

- The exploit runs on an RP2350 board; it is a tethered A12/A13 BootROM exploit. The base iPhone 11 is in scope; iPhone 12/A14 is not.
- A separate iPhone is needed to enter DFU and test the boot chain. Windows may also need a USB driver configured for libusb access before host-side DFU control works.
- The Trussh repository is an iBoot patchfinder/patcher used with usbliter8. It does not supply a Linux kernel or Android image.
- This project does not yet have a reproducible T8030 Linux boot bundle or a bootable Android device build. The setup command prepares tools and firmware; it does not install Android on a phone.
- An AOSP userspace-only target is in `android/device/apple/iphone11/`. On Linux, run `./build-android-userspace.sh /path/to/aosp-workspace` to install AOSP build packages, fetch source if needed, and build its `system.img`. That output has no iPhone kernel, DTB, vendor image, HALs, or bootloader handoff and is not flashable.
- `build-android-userspace.sh` installs AOSP packages on Ubuntu/Debian, downloads the `android-latest-release` source when given an empty workspace, and builds only the userspace `system.img`. Windows can run it through `build-android-userspace.ps1` and WSL2. Native macOS AOSP builds are unsupported; use a Linux VM instead.
- Google's AOSP build setup requires a Linux x86-64 workstation and currently recommends 400 GB free space and 64 GB RAM. The builder checks those resources before checkout; an existing source tree needs about 150 GB free for the build.

The current Android workstations and hardware blockers are recorded in [STATUS.md](STATUS.md). The linked patchfinder source snapshot and its MIT license are in `third_party/usbliter8-patchfinder/`.
