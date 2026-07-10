#!/bin/bash
#
# Command: wget -q --no-check-certificate -O - https://raw.githubusercontent.com/islam-2412/ServerColoring/main/fury/installer.sh | /bin/sh
#
echo "------------------------------------------------------------------------"
echo "                      Installing ServerColoring                         "
echo "------------------------------------------------------------------------"

# تأكد إن مسار المستودع ده صحيح ومطابق لاسم الفولدر بتاعك على GitHub
REPO_BASE_URL="https://raw.githubusercontent.com/islam-2412/ServerColoring/main/fury"
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions/ServerColoring"
COMPONENT_FILE="/usr/lib/enigma2/python/Components/EncryptedChannelManager.so"

# 1. Detect Architecture
echo "Checking system architecture..."
SYS_ARCH=$(uname -m)
case $SYS_ARCH in
    armv*|aarch32)
        ARCH="arm"
        ;;
    aarch64)
        ARCH="aarch64"
        ;;
    mips*)
        ARCH="mipsel"
        ;;
    *)
        echo "Error: Unsupported architecture ($SYS_ARCH) for this plugin."
        exit 1
        ;;
esac
echo "Detected Architecture: $ARCH"
echo ""

# 2. Detect Image Type (DreamOS vs Open Source)
IS_DREAMOS=false
if grep -qi "opendreambox" /etc/issue /etc/os-release /etc/image-version 2>/dev/null; then
    IS_DREAMOS=true
    echo "Detected Image Type: DreamOS (opendreambox)"
else
    echo "Detected Image Type: Open Source / Others"
fi
echo ""

# 3. Detect Python version on the receiver
echo "Checking Python version..."
PY_BIN=""
PY_VER=$(python -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))' 2>/dev/null)
if [ -n "$PY_VER" ]; then
    PY_BIN="python"
else
    PY_VER=$(python3 -c 'import sys; print(str(sys.version_info[0])+"."+str(sys.version_info[1]))' 2>/dev/null)
    if [ -n "$PY_VER" ]; then
        PY_BIN="python3"
    fi
fi

if [ -z "$PY_VER" ] || [ -z "$PY_BIN" ]; then
    echo "Error: Python is not installed or detected on this device!"
    exit 1
fi

echo "Detected Python Version: $PY_VER"

case $PY_VER in
   2.7|3.9|3.10|3.11|3.12|3.13|3.14|3.15)
        echo "Python $PY_VER is supported. Proceeding..."
        ;;
    *)
        echo "Error: Python $PY_VER is not supported by this plugin version."
        exit 1
        ;;
esac
echo ""

# 4. Ensure curl exists
echo "Checking if curl is installed..."
if ! command -v curl >/dev/null 2>&1; then
    if [ "$IS_DREAMOS" = true ]; then
        apt-get update > /dev/null 2>&1
        apt-get install -y curl
    else
        opkg install curl
    fi
fi
sleep 1

# 5. Remove the old version completely
echo "Removing old versions of ServerColoring completely..."
sleep 1

rm -f /tmp/servercoloring_*

if [ "$IS_DREAMOS" = true ]; then
    apt-get remove -y enigma2-plugin-extensions-servercoloring > /dev/null 2>&1
else
    opkg remove enigma2-plugin-extensions-servercoloring --force-depends > /dev/null 2>&1
fi

if [ -d "$PLUGIN_DIR" ] ; then
    rm -rf "$PLUGIN_DIR"
    echo "- Old folder /ServerColoring deleted permanently."
else
    echo "- No old folder found. System is clean."
fi

# تنظيف ملف المكونات (Component) من جذوره
if [ -f "$COMPONENT_FILE" ] ; then
    rm -f "$COMPONENT_FILE"
    echo "- Old EncryptedChannelManager.so component deleted."
fi
echo ""

# 6. Download the package
cd /tmp || exit 1

# تحديد اسم الملف بناءً على اللي طالع من سكريبت البناء build.py
if [ "$IS_DREAMOS" = true ]; then
    FILE_NAME="servercoloring_${PY_VER}_${ARCH}.deb"
else
    FILE_NAME="servercoloring_${PY_VER}_${ARCH}.ipk"
fi

DOWNLOAD_URL="${REPO_BASE_URL}/${FILE_NAME}"

echo "Downloading ServerColoring package: ${FILE_NAME} ..."

if command -v curl >/dev/null 2>&1; then
    curl -fSLk "${DOWNLOAD_URL}" -o "/tmp/${FILE_NAME}"
else
    wget -q --no-check-certificate "${DOWNLOAD_URL}" -O "/tmp/${FILE_NAME}"
fi

if [ ! -s "/tmp/${FILE_NAME}" ] || [ $(stat -c%s "/tmp/${FILE_NAME}") -lt 1000 ]; then
    echo "Error: Failed to download ${FILE_NAME} or file is corrupted."
    echo "Please check if the file exists on the GitHub repository."
    rm -f "/tmp/${FILE_NAME}"
    exit 1
fi
sleep 1

# 7. Install the update
echo ""
echo "Installing new version...."

if [ "$IS_DREAMOS" = true ]; then
    dpkg -i "/tmp/${FILE_NAME}"
    apt-get install -f -y
    INSTALL_RESULT=$?
else
    opkg install --force-reinstall --force-overwrite "/tmp/${FILE_NAME}"
    INSTALL_RESULT=$?
fi

if [ $INSTALL_RESULT -ne 0 ]; then
    echo "Error: Installation of ServerColoring failed."
    rm -f "/tmp/${FILE_NAME}"
    exit 1
fi

echo ""
sleep 1

echo "Cleaning up temporary files..."
rm -f "/tmp/${FILE_NAME}"

echo "Done"
echo "------------------------------------------------------------------------"
echo "        This work is exclusive to Islam Salama (( Skin Fury-FHD ))      "
echo "------------------------------------------------------------------------"
echo "                               Abou Yassin                              "
echo "                ServerColoring Installed Successfully                   "
echo "------------------------------------------------------------------------"
echo ""

# 8. Restart Enigma2 GUI
echo "Please wait..."
echo "Restarting Enigma2 GUI in 3 seconds to apply changes..."
sleep 3
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart enigma2
else
    killall -9 enigma2
fi

exit 0