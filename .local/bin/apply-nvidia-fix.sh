#!/bin/bash
set -e

echo "=== Applying NVIDIA DynamicPowerManagement fix ==="
echo "This lets the GPU enter low power (D3Hot) while keeping"
echo "the shared power rail alive for the touchpad."
echo ""

# Add module option to modprobe config
echo "Adding nvidia module option..."
echo 'options nvidia NVreg_DynamicPowerManagement=0x01' | sudo tee /etc/modprobe.d/nvidia-power.conf

# Add kernel cmdline parameter (for systemd-boot UKI)
echo "Adding kernel cmdline parameter..."
CMDLINE_FILE="/etc/kernel/cmdline"
PARAM="NVreg_DynamicPowerManagement=0x01"
if ! grep -q "$PARAM" "$CMDLINE_FILE"; then
    echo -n " $PARAM" | sudo tee -a "$CMDLINE_FILE"
    echo "Appended $PARAM to $CMDLINE_FILE"
else
    echo "$PARAM already present in $CMDLINE_FILE"
fi

# Rebuild initramfs
echo "Rebuilding initramfs (UKI)..."
sudo mkinitcpio -P

echo ""
echo "=== Done! Reboot to apply. ==="
echo "After reboot, the GPU will automatically enter low power"
echo "while the touchpad keeps working."
echo ""
echo "Verify with: nvidia-smi"
