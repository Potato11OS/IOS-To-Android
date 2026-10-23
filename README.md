# Android on iPhone

An experimental effort to bring up Android on selected iPhones, beginning with the iPhone 11. Hardware enablement comes first: boot a Linux kernel, identify and support the devices, then bring up Android userspace and its hardware interfaces.

This is independent research. It is not an official continuation of Corellium's Project Sandcastle and does not ship Apple firmware, keys, or device images.

## Current status

**Research and host-side prototype. No Android build or supported install exists here yet.** The first target is the base iPhone 11 (iPhone12,1 / N104AP, A13/T8030). The iPhone 12 (iPhone13,2 / D53gAP, A14/T8101) remains a separate target because the publicly documented A12/A13 boot-ROM exploit does not cover A14.

## Host setup

Windows PowerShell:

```powershell
.\setup.ps1
```

Linux or macOS:

```sh
bash setup.sh
```

To also download the usbliter8 UF2 for an RP2350 board, pass its board name, for example `--board pico2`. The setup installs host Python dependencies and prepares the exploit tools. The project now has an AOSP userspace-only seed, but it cannot boot on an iPhone because the Linux kernel, matching device tree, boot path, vendor image, and hardware services are missing.

## Android userspace build seed

The first AOSP product definition is in [android/device/apple/iphone11](android/device/apple/iphone11/README.md). On a suitable Linux machine, run:

```sh
bash build-android-userspace.sh /path/to/aosp-workspace
```

The script installs AOSP build packages on Ubuntu/Debian, checks resources, downloads the current AOSP release source into the selected workspace, stages the product definition, and builds `system.img` only. Windows can use `build-android-userspace.ps1` with a WSL2 path. Native macOS AOSP builds are unsupported; use a Linux VM. This does not produce an iPhone boot image or install anything on a phone.

```powershell
.\build-android-userspace.ps1 -AospRoot /home/dev/aosp-iphone11
```

| Target | Chip | Starting position |
| --- | --- | --- |
| iPhone 11 (iPhone12,1 / N104AP) | A13 / T8030 | First target. A public tethered boot-ROM exploit exists, and Linux booting on an iPhone 11 was reported in October 2026. A reproducible, public Android port is still a separate body of work. |
| iPhone 12 (iPhone13,2 / D53gAP) | A14 / T8101 | Later target. Needs a verified way to load a custom OS; the A12/A13 `usbliter8` exploit does not support A14. |

Project Sandcastle's published Android and Linux builds list iPhone 7, iPhone 7 Plus, and iPod touch (7th generation), not iPhone 11 or 12. Existing A13 Linux work is useful reference material, not a drop-in Android port.

### No-phone development lead: Inferno

[ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) is a QEMU-derived Apple ARM device emulator with a T8030/iPhone 11 machine. We built its ARM64 and x86_64 emulator targets in WSL2 at [commit `cc4302a`](https://github.com/ChefKissInc/Inferno/commit/cc4302a99167abec69b714cfd00c38caece7e7de). Source inspection shows the T8030 boot path expects Apple's IM4P-wrapped Mach-O kernel cache, not a standard Linux `Image`; Linux-on-Inferno remains unproven and needs a Linux-specific boot path. An August 2026 discussion post claims an iOS 16.5.1 boot on the emulated phone, but a project maintainer disputes that post and says related work is unreleased; treat the claim as unverified. The emulator's issue tracker lists AGX/SGX GPU emulation as future work and has open T8030 peripheral work, including USB. Initially treat Inferno as an external tool: its licensing includes GPLv3 and AGPLv3 portions alongside upstream QEMU licenses.

The recent [`ios-sweet`](https://github.com/dipa-studio/ios-sweet) work runs iOS/XNU on an Android phone, which is the reverse direction. Its authors describe it as experimental and report CPU-only rendering; it does not supply an iPhone boot path or drivers for this project. It is still a useful example of how much hardware-specific work a cross-device OS port involves.

## Milestones

1. Record exact device variants, firmware, host tools, and a recovery path.
2. Establish a repeatable boot path and capture a minimal Linux shell on iPhone 11.
3. Bring up core Linux hardware support, starting with USB, display, touch, power, and storage read-only.
4. Inventory sensors on the exact device and implement/test each Linux driver and Android Sensor HAL mapping.
5. Investigate the A13 GPU path, then deliver hardware acceleration only after kernel, firmware, and userspace support work together.
6. Adapt an Android userspace to the working kernel and HALs; document repeatable boot and recovery.
7. Revisit iPhone 12 when a viable A14 custom-boot path is demonstrated.

The detailed gates and evidence requirements are in [docs/ROADMAP.md](docs/ROADMAP.md).

## Non-goals for the first milestone

- Claiming broad device support from a successful boot on one handset.
- Treating a jailbreak as proof that a custom OS can boot.
- Writing to the iPhone's internal storage before boot and recovery are repeatable.
- Claiming “all sensors” or GPU acceleration without a per-device test record.

## References

- [Project Sandcastle status and supported devices](https://projectsandcastle.org/status)
- [Project Sandcastle source repository](https://github.com/corellium/projectsandcastle)
- [usbliter8 A12/A13 BootROM exploit](https://github.com/JoshAtticus/usbliter8)
- [Trussh iBoot patchfinder](https://github.com/Trussh/usbliter8) (vendored MIT source snapshot in `third_party/usbliter8-patchfinder/`)
- [Hoolock A13 feature status](https://github.com/yhavry/Hoolock-Docs-A13/blob/master/features/A13.md)
- [Apple device and board identifiers (ipsw)](https://blacktop.github.io/ipsw/docs/guides/device_list/)
- [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno)
- [Inferno T8030/iPhone 11 emulation discussion](https://github.com/ChefKissInc/Inferno/discussions/312)
- [Inferno Windows/WSL discussion](https://github.com/ChefKissInc/Inferno/discussions/212)
- [Reported Linux boot on iPhone 11](https://www.patreon.com/partshacker/posts/linux-boots-on-172091834)
- [Asahi Linux AGX GPU architecture notes](https://asahilinux.org/docs/hw/soc/agx/)
