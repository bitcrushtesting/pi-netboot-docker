#!/bin/bash -e

echo "Start the TFTP server"
service tftpd-hpa start

#echo "Start the NFS server"
#service nfs-kernel-server start

# Keep the container running
tail -f /dev/null
