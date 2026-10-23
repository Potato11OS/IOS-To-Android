# Project status

Updated 2026-10-23.

## What we have

- The project is initialized with a README and staged bring-up roadmap.
- The first target remains iPhone 11 (A13/T8030); iPhone 12 (A14/T8101) is a later, separate target.
- The linked [Trussh/usbliter8](https://github.com/Trussh/usbliter8) repository is an MIT-licensed iBoot/iBSS/iBEC patchfinder, not the BootROM exploit itself. Its source snapshot is pinned under `third_party/usbliter8-patchfinder/` at `09d87ddd5e445a08c262829883e96bfb1f90631f`.
- The separate [usbliter8 BootROM project](https://github.com/JoshAtticus/usbliter8) supports A12/A13 and requires an RP2350 board for the A13 iPhone 11 exploit path. It is tethered; it does not provide an Android kernel or image. Its upstream repository has no license file, so the setup script fetches the pinned `479dbbf4ad80e4a454e0779d1b4d1ec5eb0d7bd5` checkout locally instead of vendoring its source.
- Cross-platform setup entrypoints now prepare a project-local Python environment, install the pinned host packages, fetch the exploit source, and optionally download an official RP2350 UF2. They do not touch a connected device or claim Android installation.
- The Windows `setup.ps1` path completed on this host and installed Capstone 5.0.9, PyUSB 1.3.1, and libusb-package 1.0.30.0 into the project `.venv`. The Linux/macOS entrypoint is present but has not been run on those operating systems.
- Public A13 kernel notes describe a development branch and some T8030 support, but the feature page calls out an iPhone 11 Pro variant. Results must be checked on the base iPhone 11 before we can claim it is supported.
- A recent Parts Hacker report says base iPhone 11 (T8030) boots a custom Linux 7.1 kernel with a custom bootloader, all six CPU cores, 4 GB RAM, and USB CDC networking/serial. The authors say the initial kernel patch set is forthcoming. This is a Linux bring-up report, not an Android port, and we do not yet have public source here that reproduces it.
- Added an initial AOSP `aosp_iphone11_userspace` product target and a Linux build helper. It can build a system image only from a separately provisioned AOSP checkout on a machine meeting AOSP's requirements. It has no boot image, kernel, DTB, vendor image, or device HALs and cannot boot on a phone.
- The Android source download/build has not been run here: this workstation has about 16 GB RAM and 62 GB free on C:, below the AOSP source/build requirements. The helper will stop at its resource check before installing packages or syncing source.
- ChefKiss Inferno emulates the T8030/iPhone 11 machine in QEMU. One discussion poster claims iOS 16.5.1 booted in the emulator, but a project maintainer disputes the post and says related work is unreleased; treat it as unverified. Linux guest boot is also unverified, though it may provide a no-phone kernel sandbox. Its AGX/SGX emulation is listed as future work, with open T8030 peripheral issues.
- WSL 3.0.3 with Ubuntu 24.04.5 LTS is installed and running as WSL2. The default Linux account is `dev`; CPU firmware virtualization, Virtual Machine Platform, and the WSL optional component are enabled.
- Inferno was cloned at commit [`cc4302a99167abec69b714cfd00c38caece7e7de`](https://github.com/ChefKissInc/Inferno/commit/cc4302a99167abec69b714cfd00c38caece7e7de). Its upstream Linux CI build settings configured `aarch64-softmmu` and `x86_64-softmmu`, and `ninja -C build -j6` completed successfully. Configuration needed Meson 1.5+ and Nettle 3.10+; Ubuntu's Meson/Nettle packages were older, so Meson 1.12.1 was installed in a venv and the CI-pinned Nettle 3.10.2 was built from its hash-verified source archive. The shallow clone also needed the `util/mlib` submodule.
- Inferno's Linux guest blocker is now mapped more precisely from source: [`apple_boot_load_kernel()`](https://github.com/ChefKissInc/Inferno/blob/cc4302a99167abec69b714cfd00c38caece7e7de/hw/arm/apple-silicon/boot.c) expects an Apple IM4P containing a Mach-O kernel. T8030 initialization also loads Apple's serialized device tree to construct the emulated board and its machine state; reset starts the Apple kernel at its Mach-O entry with Apple boot arguments. A Linux mode therefore needs a separate flat Linux DTB and Linux ARM64 entry/reset handling while retaining the Apple tree (or replacing its board-construction role). This Inferno change would only enable emulator experiments; no Linux guest boot is claimed.

## Current blockers

### No test iPhone

The project owner does not currently have an iPhone test device. That prevents validation of boot stages, device trees, drivers, sensors, display, and GPU work. We can still do source review and host-side preparation, but hardware claims must wait until we can access a device.

### Build environment

The current workstation is Windows with Ubuntu 24.04.5 available through WSL2. The Inferno build toolchain is installed inside Ubuntu. The machine has about 16 GB RAM and 62 GB free on C:; this is enough for the emulator and small kernel experiments but not a full local AOSP checkout/build.

Google's current AOSP setup guide specifies a 64-bit Linux workstation, at least 400 GB free disk, and at least 64 GB RAM for an Android source checkout and build; native macOS builds are unsupported. This machine is therefore not suitable for a full local AOSP build as configured. A Linux environment with more memory and storage, or a suitable hosted build, will be needed for that milestone. Linux-kernel source review and smaller kernel builds have lower requirements, but still need a Linux toolchain.

## Work that can proceed without the phone

1. Track publication of the reported base-iPhone-11 Linux kernel and bootloader sources; pin their revisions and determine whether they provide a reusable Linux DTB/config for Android work.
2. Keep the Inferno Linux-loader experiment separate: it needs independent Linux Image/FDT loading and reset setup, and cannot validate physical GPU or sensor support.
3. Separate generic A13 support from iPhone 11 base-specific work and identify what evidence each feature needs.
4. Find a larger Linux build host for AOSP; the current WSL2 setup is ready for emulator and small kernel work.
5. Keep Android userspace integration, sensor validation, GPU validation, and physical boot claims marked as pending until source and hardware evidence exist.

## References

- [A13/T8030 feature notes](https://github.com/yhavry/Hoolock-Docs-A13/blob/master/features/A13.md)
- [iPhone 11 Linux boot report](https://www.patreon.com/partshacker/posts/linux-boots-on-172091834)
- [AOSP build workstation requirements](https://source.android.com/docs/setup/start)
- [Linux kernel LLVM cross-compilation documentation](https://docs.kernel.org/kbuild/llvm.html)
- [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno)
- [Inferno T8030/iPhone 11 emulation discussion](https://github.com/ChefKissInc/Inferno/discussions/312)
- [Inferno AGX/SGX emulation tracker](https://github.com/ChefKissInc/Inferno/issues/274)
- [Inferno DWC3 USB tracker](https://github.com/ChefKissInc/Inferno/issues/233)
- [Inferno Windows/WSL discussion](https://github.com/ChefKissInc/Inferno/discussions/212)
- [Pinned Inferno T8030 kernel loader](https://github.com/ChefKissInc/Inferno/blob/cc4302a99167abec69b714cfd00c38caece7e7de/hw/arm/apple-silicon/boot.c)
