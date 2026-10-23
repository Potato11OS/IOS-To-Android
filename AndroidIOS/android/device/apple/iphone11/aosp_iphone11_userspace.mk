$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/handheld_system.mk)
$(call inherit-product, device/apple/iphone11/device.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_product.mk)

PRODUCT_NAME := aosp_iphone11_userspace
PRODUCT_DEVICE := iphone11
PRODUCT_BRAND := AndroidIOS
PRODUCT_MODEL := Android userspace for iPhone 11 (not bootable)
PRODUCT_MANUFACTURER := Apple
