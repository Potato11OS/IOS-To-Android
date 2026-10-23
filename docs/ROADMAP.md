# Bring-up roadmap

Updated 2026-10-23. This roadmap separates evidence-backed starting points from work that still needs to be done. A stage is complete only when its evidence can be reproduced on the named device variant.

## Target order

### 1. iPhone 11 base (iPhone12,1 / N104AP / A13/T8030)

Start here. The `usbliter8` project documents a tethered BootROM exploit for A12 and A13. Separately, Linux booting on an iPhone 11 with a custom bootloader was reported in October 2026. That report describes a Linux 7.1 shell, all six CPU cores, 4 GB RAM, and USB CDC, while saying the initial upstream kernel patch set is forthcoming. This establishes a promising lead, not a build we can yet reproduce from this repository.

The Hoolock A13 feature notes point to T8030 development commit `38e339f66253b40b046ef84bd910426eba12f822` and show useful work, including SMC functions, CPU frequency control, hardware monitoring, backlight control, and an iBoot-initialized framebuffer. They mark native display modesetting as work in progress and document the iPhone 11 Pro (iPhone12,3 / D421AP) display variant. That is a different device-tree target from the base iPhone 11 (iPhone12,1 / N104AP), so we must verify each result on the base model before treating it as supported. Device identifiers are cross-referenced in the [ipsw device list](https://blacktop.github.io/ipsw/docs/guides/device_list/).

### 2. iPhone 12 (A14/T8101)

Keep this on the roadmap, but do not infer a boot path from A13. `usbliter8` currently targets A12/A13, while the iPhone 12 is A14. First require a repeatable, authorized custom-code boot method and a demonstrated recovery route for the exact target. A jailbreak or cross-compiled kernel alone does not satisfy this gate.

## Parallel no-phone track: Inferno feasibility

[ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) is a QEMU derivative with an Apple T8030 machine. An August 2026 discussion post claims an iOS 16.5.1 boot for the base iPhone 11 (N104AP), but a project maintainer disputes the post and says related work is unreleased. Treat the claim as unverified; it does not establish a reproducible public boot path. Inferno may still be useful for kernel experiments before a physical phone is available.

This is an experiment, not an assumed capability: Inferno's public materials describe Apple ARM guest support, but we have not established that its T8030 machine boots a Linux kernel. A successful emulated boot would not validate real-device boot behavior or hardware drivers. The emulator tracks AGX/SGX emulation as a future feature, and its T8030 peripheral model has open work including DWC3 USB, so it cannot currently prove sensor or GPU support. See [AGX/SGX emulation](https://github.com/ChefKissInc/Inferno/issues/274), [DWC3 USB issue](https://github.com/ChefKissInc/Inferno/issues/233), and the [iPhone 11 emulation discussion](https://github.com/ChefKissInc/Inferno/discussions/312).

Use Inferno as an external development tool initially rather than vendoring its QEMU fork. The repository identifies its own code as AGPLv3 and the derivative as GPLv3, while retaining upstream QEMU licensing terms for some components; review the current license files before copying or distributing any code.

### E0 — Test whether Inferno can boot Linux

- Establish a reproducible Inferno build/run environment.
- Determine the expected kernel image format, boot arguments, and device-tree representation for an ARM64 Linux guest on its T8030 machine.
- Attempt a minimal kernel plus initramfs and capture serial output; document unsupported devices or boot blockers.
- Keep emulator results separate from physical-device results throughout the project.

**Current result (2026-10-23):** Inferno commit [`cc4302a99167`](https://github.com/ChefKissInc/Inferno/commit/cc4302a99167abec69b714cfd00c38caece7e7de) built successfully in Ubuntu 24.04.5 under WSL2 for `aarch64-softmmu` and `x86_64-softmmu`. A generic Linux boot has not been attempted: the T8030 machine's [`apple_boot_load_kernel()`](https://github.com/ChefKissInc/Inferno/blob/cc4302a99167abec69b714cfd00c38caece7e7de/hw/arm/apple-silicon/boot.c) unwraps an Apple IM4P and then parses a Mach-O kernel. The [T8030 setup](https://github.com/ChefKissInc/Inferno/blob/cc4302a99167abec69b714cfd00c38caece7e7de/hw/arm/apple-silicon/t8030.c) also depends on Apple's serialized device tree to build the emulated board, then resets the CPU to the Apple kernel entry with Apple boot arguments. The QEMU ARM code in this revision already has a generic ARM64 `Image`/flat-DTB loader, but the T8030 machine does not use it, and its custom CPU reset would still select the Apple entry and arguments. A Linux mode therefore needs independent Linux image/DTB/cmdline inputs, a Linux handoff/reset path, and must keep the Apple tree available for T8030 board construction. A standard ARM64 Linux `Image` has no supported T8030 entry path in this revision; no Linux guest boot is claimed.

**Next no-phone action:** prototype that Linux path as an opt-in Inferno mode, leaving the Apple boot path intact. Start with a serial-only minimal Linux kernel and its matching T8030 flat DTB; do not start Android integration until that kernel reaches a shell. The reported iPhone 11 Linux patch set is not yet public, so the kernel and DTB needed for a meaningful boot remain an external dependency. This emulator milestone can exercise loader and kernel startup logic, but cannot validate physical sensors, GPU acceleration, or the real phone's boot chain.

**Exit evidence:** either a reproducible Linux shell in Inferno with pinned emulator revision and command line, or a concise, source-backed explanation of the first blocker. No emulator result closes a real-device gate.

## Gates

### G0 — Freeze the test target

- The planned first target is the base iPhone 11: `iPhone12,1` / `N104AP` / T8030. When a physical unit is available, record its exact model identifier, board variant, iOS build, and host OS from the device and firmware metadata.
- Keep iPhone 11 base, Pro, and Pro Max results separate until hardware equivalence is demonstrated.
- Pin source revisions and preserve boot logs and observed results alongside each change.

**Exit evidence:** a checked-in target record with exact identifiers, source revisions, and a tested recovery procedure.

### G1 — Repeatable custom boot

- Reproduce the boot path from a cold start on the named iPhone 11 variant.
- Identify every stage and its source; record required external hardware and host tooling.
- Demonstrate recovery to the stock OS before proceeding to persistent changes.

**Exit evidence:** repeatable boot logs and a recovery run recorded for the same device and firmware build.

### G2 — Linux baseline

- Boot a minimal Linux userspace and capture a serial or USB console.
- Confirm CPU topology, RAM map, interrupt/timer operation, reboot, and thermal behavior.
- Keep internal storage read-only while the boot and recovery path is being established.

**Exit evidence:** a reproducible shell, logs, and a device tree tied to the exact target.

### G3 — Essential devices

Bring up and record each subsystem independently: USB, display/backlight, touch, storage, Wi-Fi, Bluetooth, audio, cameras, cellular, charging, and suspend/resume. Some may remain unsupported; a boot does not imply they work.

**Exit evidence:** a per-device matrix with the driver, test procedure, observed result, and remaining limitations for every subsystem.

### G4 — Sensors

- Inventory the actual components and their buses on each target variant before writing a HAL.
- Trace the Linux-facing interfaces for motion, orientation, proximity, ambient light, pressure, and other sensors actually present.
- Implement or adapt Linux drivers, then map only working devices through Android's Sensors HAL. The framework expects stable sensor identities and correctly timed, independently configurable event streams; exposing a name in the HAL is not enough.
- Check accuracy, sampling, timestamps, wake-up behavior, and suspend/resume.

**Exit evidence:** named sensor-by-sensor test results on-device and Android Sensor HAL results. “All sensors work” requires the inventory to be complete for the named model.

### G5 — GPU acceleration

The target GPU is Apple AGX. Asahi's public driver work is a valuable architectural reference, but its existence does not establish compatibility with the iPhone 11's T8030 GPU. The bring-up must verify the target's GPU firmware interface, memory translation, power/interrupt paths, kernel driver, and userspace API stack, then integrate it with Android's graphics stack (buffer allocation, composition, and GLES and/or Vulkan). Start with a stable framebuffer and software rendering while hardware acceleration is unavailable.

**Exit evidence:** a GPU driver initializes reliably, an Android graphics API reports the hardware renderer, and representative graphics workloads complete without rendering errors or device instability. Record performance and power separately from functional status.

### G6 — Android userspace

- Select an AOSP release after the Linux baseline and page-size/runtime constraints are known.
- Provide the required Android device configuration and HALs for the subsystems that passed earlier gates.
- Boot from a temporary or otherwise recoverable setup before considering persistent installation.

**Exit evidence:** Android boots repeatedly on the named device, with a documented list of working and unavailable functions.

## Known constraints and references

- Sandcastle's published builds currently list iPhone 7, iPhone 7 Plus, and iPod touch (7th generation): [official status page](https://projectsandcastle.org/status).
- The public [`usbliter8` repository](https://github.com/JoshAtticus/usbliter8) describes A12/A13 support, not A14.
- The [Hoolock A13 feature table](https://github.com/yhavry/Hoolock-Docs-A13/blob/master/features/A13.md) is useful kernel reference work; it is not proof of support for every A13 iPhone variant.
- The [iPhone 11 Linux boot report](https://www.patreon.com/partshacker/posts/linux-boots-on-172091834) is recent primary-source evidence, but its initial upstream patch set was not yet published in the report.
- [ChefKiss Inferno](https://github.com/ChefKissInc/Inferno) is a possible no-phone experiment target. Its [iOS boot discussion](https://github.com/ChefKissInc/Inferno/discussions/312) contains a disputed, unverified claim; Linux guest support is not established.
- The Inferno maintainers say [Windows is supported](https://github.com/ChefKissInc/Inferno/discussions/212), though they do not provide setup instructions; a community reply suggests WSL.
- Inferno currently lists AGX/SGX emulation as [future work](https://github.com/ChefKissInc/Inferno/issues/274), and its T8030 device model has open [DWC3 USB work](https://github.com/ChefKissInc/Inferno/issues/233).
- [Asahi Linux's AGX notes](https://asahilinux.org/docs/hw/soc/agx/) describe the architecture and firmware-mediated GPU stack. Porting that work to T8030 remains unproven.
- Android's [Sensors HAL documentation](https://source.android.com/docs/core/interaction/sensors/sensors-aidl-hal) defines the framework contract for sensor enumeration and events.
- Android's [graphics architecture documentation](https://source.android.com/docs/core/graphics/architecture) describes the driver, buffer, composition, GLES, and Vulkan components needed for accelerated rendering.
