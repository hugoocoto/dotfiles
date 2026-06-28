#!/bin/bash
set -eE
trap 'echo "  ERROR at line $LINENO"' ERR

echo "=== MControlCenter Installer ==="

echo "[1/4] Loading msi-ec kernel module..."
BIOS=$(cat /sys/devices/virtual/dmi/id/bios_version)
PRODUCT=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Unknown")
echo "  Laptop: $PRODUCT"
echo "  BIOS:   $BIOS"

# Stage A: Blacklist in-tree module
BLACKLISTED=false
for f in /etc/modprobe.d/*.conf; do
    [ -f "$f" ] && grep -qs "blacklist msi-ec" "$f" && BLACKLISTED=true && break
done
if ! $BLACKLISTED; then
    echo "  Blacklisting in-tree msi-ec..."
    echo "blacklist msi-ec" | sudo tee /etc/modprobe.d/msi-ec-blacklist.conf >/dev/null
fi

# Stage B: Install fork via DKMS if not present
if ! modinfo msi_ec 2>/dev/null | grep -q "BeardOverflow"; then
    echo "  Building forked msi-ec from BeardOverflow..."
    [ -d /tmp/msi-ec ] && rm -rf /tmp/msi-ec
    git clone --depth=1 https://github.com/BeardOverflow/msi-ec /tmp/msi-ec
    sudo make -C /tmp/msi-ec dkms-uninstall 2>/dev/null || true
    sudo make -C /tmp/msi-ec dkms-install
    echo "  Fork installed via DKMS"
fi

# Stage C: Try auto-detection
EC_FW=""
if sudo modprobe msi-ec 2>/dev/null; then
    echo "  msi-ec loaded (auto-detected)"
    if [ -f /sys/devices/platform/msi-ec/fw_version ]; then
        EC_FW=$(cat /sys/devices/platform/msi-ec/fw_version)
    fi
else
    echo "  Auto-detection failed — firmware not in whitelist."

    # Stage D: Load debug=1 to read real EC firmware
    echo "  Loading in debug mode to detect EC firmware..."
    sudo modprobe msi-ec debug=1
    sleep 1

    if [ -f /sys/devices/platform/msi-ec/debug/fw_version ]; then
        EC_FW=$(cat /sys/devices/platform/msi-ec/debug/fw_version)
        echo "  Real EC firmware: $EC_FW"

        # Stage E: Search for EC firmware in source
        MATCHED_FW=$(grep -oF "\"$EC_FW\"" /tmp/msi-ec/msi-ec.c 2>/dev/null || true)
        if [ -n "$MATCHED_FW" ]; then
            echo "  Exact match found in driver!"
        fi

        # Stage F: Unload debug, reload with matched or experimental config
        sudo modprobe -r msi-ec 2>/dev/null || true
        sleep 1

        if [ -n "$MATCHED_FW" ]; then
            sudo modprobe msi-ec firmware="$MATCHED_FW"
            echo "  Loaded with config: $MATCHED_FW"
        else
            echo "  WARNING: $EC_FW not in driver's device list."
            echo "  Trying closest firmware config 14F1EMS1.112 (experimental)..."
            echo "  If values are wrong, see: https://github.com/BeardOverflow/msi-ec/issues"
            if sudo modprobe msi-ec firmware=14F1EMS1.112; then
                EC_FW="14F1EMS1.112"
            else
                echo "  Closest config also failed."
                echo "  Falling back to debug mode (limited features)."
                sudo modprobe msi-ec debug=1
                EC_FW=""
            fi
        fi
    else
        echo "  ERROR: Debug mode could not read EC firmware."
        sudo modprobe -r msi-ec 2>/dev/null || true
        sudo modprobe msi-ec debug=1 2>/dev/null || true
    fi
fi

# Stage G: Verification
if lsmod | grep -q msi_ec; then
    echo "  msi-ec loaded successfully"
else
    echo "  WARNING: msi-ec not loaded — EC features unavailable."
    echo "  See: https://github.com/BeardOverflow/msi-ec/issues"
fi

# Stage H: Persist
if lsmod | grep -q msi_ec; then
    echo "msi-ec" | sudo tee /etc/modules-load.d/msi-ec.conf >/dev/null
fi

if [ -n "$EC_FW" ]; then
    echo "options msi-ec firmware=$EC_FW" | sudo tee /etc/modprobe.d/msi-ec-fix.conf >/dev/null
fi

# Also load ec_sys for raw EC access (fallback for MControlCenter)
sudo modprobe ec_sys write_support=1
echo "ec_sys" | sudo tee /etc/modules-load.d/ec_sys.conf >/dev/null
echo "options ec_sys write_support=1" | sudo tee /etc/modprobe.d/ec_sys.conf >/dev/null

echo "[2/4] Downloading MControlCenter..."
LATEST=$(curl -sL https://api.github.com/repos/dmitry-s93/MControlCenter/releases/latest \
    | grep "tag_name" | cut -d'"' -f4)
echo "  Latest version: $LATEST"
curl -Lo /tmp/MControlCenter.tar.gz \
    "https://github.com/dmitry-s93/MControlCenter/releases/download/$LATEST/MControlCenter-${LATEST#v}-bin.tar.gz"

echo "[3/4] Extracting..."
mkdir -p /tmp/mcc
tar -xzf /tmp/MControlCenter.tar.gz -C /tmp/mcc
cd /tmp/mcc/MControlCenter-*

echo "[4/4] Installing..."
sudo ./install.sh

rm -rf /tmp/mcc /tmp/MControlCenter.tar.gz

echo "=== Done! Launch with: mcontrolcenter ==="
