#!/bin/bash

VIDEO_DEV="/dev/video9"

echo "Adding v4l2loopback camera $VIDEO_DEV"
sudo modprobe v4l2loopback devices=1 video_nr=9 card_label="Android_Webcam" exclusive_caps=1

echo "Waiting for device"
adb wait-for-device

echo "Starting scrcpy"
scrcpy --video-source=camera --camera-facing=back --camera-size=1920x1080 --v4l2-sink=$VIDEO_DEV --no-window --no-audio

sudo modprobe -r v4l2loopback
