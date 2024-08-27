#!/bin/bash -e

# Copyright © 2024 Bitcrush Testing

DEPLOY_DIR="./pi-gen/deploy"
BOOT_MNT_DIR="/mnt/rpi-boot"
ROOT_MNT_DIR="/mnt/rpi-root"
TFTP_DIR="/srv/tftp/boot"
NFS_DIR="/srv/nfs/root"


clean_up()
{
    sudo umount -fq "${BOOT_MNT_DIR}" || true
    sudo umount -fq "${ROOT_MNT_DIR}" || true
   
    sudo rm -rf "${BOOT_MNT_DIR}"
    sudo rm -rf "${ROOT_MNT_DIR}"

    sudo rm -rf "${TFTP_DIR}"
    sudo rm -rf "${NFS_DIR}"
    echo "----- DONE -----"    
    exit 0
}

USER_ID=$(id -u)
if [[ "$USER_ID" -eq 0 ]]; then
    echo "Must not run with sudo"
    exit 1
fi


# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --image) 
            IMAGE_FILE="$2"
            shift 2
            ;;
        --clean)
            shift 1
            clean_up
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

# Check if the image file was provided
if [[ -z "$IMAGE_FILE" ]]; then
    IMAGE_NAME="$(find ${DEPLOY_DIR} -type f -name "*.img" | head -n 1)"
    IMAGE_FILE="${DEPLOY_DIR}/${IMAGE_NAME}"
    echo "Using default image: ${IMAGE_FILE}"
fi

# Create a loop device and map the partitions
LOOP_DEVICE=$(sudo losetup --show -fP "$IMAGE_FILE")

echo "Mount the boot partition of the image to ${BOOT_MNT_DIR}"
sudo umount -fq "${BOOT_MNT_DIR}" || true
sudo mkdir -p "${BOOT_MNT_DIR}"
sudo mount "${LOOP_DEVICE}p1" "${BOOT_MNT_DIR}"
echo "Moving the boot files to the TFTP dir ${TFTP_DIR}"
sudo mkdir -p "${TFTP_DIR}"
sudo rm -rf "${TFTP_DIR}/*"
sudo chown "${USER}" "${TFTP_DIR}"
sudo cp -a "${BOOT_MNT_DIR}/." "${TFTP_DIR}"
sudo umount "${BOOT_MNT_DIR}"

echo "Mount the root partition of the image to ${ROOT_MNT_DIR}"
sudo umount -fq "${ROOT_MNT_DIR}" || true
sudo mkdir -p "${ROOT_MNT_DIR}"
sudo mount "${LOOP_DEVICE}p2" "${ROOT_MNT_DIR}"
echo "Moving the root files to the NFS dir ${NFS_DIR}"
sudo mkdir -p "$NFS_DIR"
sudo rm -rf "${NFS_DIR}/*"
sudo chown "$USER" "$NFS_DIR"
sudo cp -a "${ROOT_MNT_DIR}/." "$NFS_DIR"
sudo umount "${ROOT_MNT_DIR}"

sudo losetup -d "$LOOP_DEVICE"

echo "------ DONE ------"
