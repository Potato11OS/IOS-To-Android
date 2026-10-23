# Android build path

The Android target begins at the AOSP product layer, but a framework build and
a bootable iPhone image are different milestones.

## Current artifact

`android/device/apple/iphone11/` registers an ARM64 `userdebug` product named
`aosp_iphone11_userspace`. It is intended to build Android's system image for
userspace experiments. It has no kernel, DTB, vendor image, display or input
HAL, sensor HAL, or GPU stack, so it cannot boot on an iPhone.

On a suitable Ubuntu/Debian Linux host, run:

```sh
./build-android-userspace.sh /path/to/aosp-workspace
```

The script installs AOSP's Ubuntu/Debian build packages and Repo launcher,
checks the host resources before downloading source, initializes the current
`android-latest-release` manifest in an empty workspace, syncs the AOSP source,
stages the product directory, then runs `lunch aosp_iphone11_userspace aosp_current userdebug` and `m systemimage`. It requires 64 GB RAM and
about 400 GB free before checkout, or about 150 GB free if the source is already
checked out. The build output is under `out/target/product/iphone11/`.

On Windows, pass a WSL2 path for the source workspace:

```powershell
.\build-android-userspace.ps1 -AospRoot /home/dev/aosp-iphone11
```

The Windows wrapper runs the Linux builder inside the default WSL2 distribution.

## Platform boundary

The dependency/bootstrap scripts can run on Windows, Linux, and macOS. Building
AOSP itself requires Linux; Windows use is through WSL2, and Google's current
setup guide no longer supports native macOS AOSP development. A macOS user would
need a Linux VM with enough RAM and disk. The one-command build helper downloads
the multi-hundred-gigabyte AOSP checkout only after checking available resources.

## Required before a phone image

- Public, pinned Linux kernel source validated for the base iPhone 11 board
  (`N104AP`), plus its kernel configuration and Android-required kernel options.
- Matching Linux flat device tree and a documented memory/interrupt map.
- Reproducible custom bootloader handoff to the ARM64 Linux entry point.
- Device-specific vendor services and HALs, with source or a permitted interface.
- Sensor inventory and drivers, then an Android Sensors HAL implementation.
- Display/touch support and a tested graphics path before claiming GPU acceleration.
- Partition and boot-image layout derived from the real boot chain, not guessed.

The report of Linux 7.1 on iPhone 11 is promising, but it says its initial
kernel patch set is forthcoming. This target remains a userspace seed until
those inputs are public and reproducible.

## References

- [AOSP workstation requirements](https://source.android.com/docs/setup/start/requirements)
- [AOSP source checkout and release branch](https://source.android.com/docs/setup/download)
- [AOSP device product configuration](https://source.android.com/docs/setup/create/new-device)
- [iPhone 11 Linux 7.1 report](https://www.patreon.com/partshacker/posts/linux-boots-on-172091834)
