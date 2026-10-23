# This target builds Android userspace only. The T8030 kernel and boot path
# must be defined from reproducible iPhone 11 Linux sources before images are
# generated for a physical device.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_VARIANT := generic
TARGET_CPU_ABI := arm64-v8a
TARGET_USES_64_BIT_BINDER := true

TARGET_NO_BOOTLOADER := true
TARGET_NO_KERNEL := true

# Reuse AOSP's generic system-image sizing/filesystem defaults for this
# non-bootable userspace build; this does not define an iPhone partition map.
include build/make/target/board/BoardConfigGsiCommon.mk
