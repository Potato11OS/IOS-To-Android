# iPhone 11 Android userspace seed

This is an initial AOSP product definition for the base iPhone 11 target
(`iPhone12,1` / `N104AP` / `A13` / `T8030`). It is a framework/userspace build
seed only. It deliberately does not define a kernel, DTB, boot image, vendor
partition, hardware HAL, sensor, or GPU driver, so it cannot boot on an iPhone.
Its generic system-image settings are only for producing `system.img`; they are
not an iPhone partition layout or a promise that the image can be flashed.

To use it, place this directory at `device/apple/iphone11` in an AOSP source
tree, then select `aosp_iphone11_userspace-userdebug`. Build `systemimage` only;
the result is generic Android userspace for development and is not a flashable
phone image. AOSP's generic ARM64 emulator/GSI products have different goals,
so this product does not inherit their emulator device or vendor configuration.

The physical-device product can only be completed after a reproducible N104AP
Linux kernel source, matching DTB, Android kernel requirements, and the Linux
boot protocol are available. The October 2026 Linux 7.1 report says the initial
kernel patch set is forthcoming; no boot artifacts are available in this
project yet.
