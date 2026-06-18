#!/bin/bash

# update mirrorlist.
sudo reflector --country France --fastest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# update the system.
sudo pacman -Syyu
