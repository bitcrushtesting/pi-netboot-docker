#!/bin/bash

# Bitcrush Testing 2024

NETWORK_INTERFACE="eno1"
TFTP_ROOT="/srv/tftp"
DHCP_RANGE_START="192.168.1.1"
DHCP_RANGE_END="192.168.1.250"
LEASE_TIME="12h"
PXE_BOOT_FILE="bootcode.bin"

# Function to check if a package is installed
check_installation() {
  if dpkg -s "$1" >/dev/null 2>&1; then
    echo "$1 is already installed."
  else
    echo "$1 is not installed. Installing..."
    sudo apt-get install -y "$1"
  fi
}

# Update system and install required packages
sudo apt-get update
check_installation "dnsmasq"

# Backup the original dnsmasq configuration file
if [ -f /etc/dnsmasq.conf ]; then
  sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
  echo "Original dnsmasq.conf file backed up."
fi

# Create a new dnsmasq configuration file
sudo tee /etc/dnsmasq.conf > /dev/null <<EOL
interface=${NETWORK_INTERFACE}
dhcp-range=${DHCP_RANGE_START},${DHCP_RANGE_END},${LEASE_TIME}

# Enable TFTP server
enable-tftp
tftp-root=${TFTP_ROOT}

# Set the boot file name
dhcp-boot=${PXE_BOOT_FILE}

# Ensure the Raspberry Pi uses this file to boot
pxe-service=0,"Raspberry Pi Boot"
EOL

echo "dnsmasq configuration file created."

# Restart dnsmasq to apply changes
sudo systemctl restart dnsmasq
echo "dnsmasq service restarted."

echo "DHCP server setup for PXE booting is complete."
echo "----- DONE -----"
