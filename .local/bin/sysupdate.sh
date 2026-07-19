#!/bin/bash

# update mirrorlist.
echo "Updating mirrorlists"
sudo reflector --country France --fastest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# update the system.
echo "Updating the system"
sudo pacman -Syyu
