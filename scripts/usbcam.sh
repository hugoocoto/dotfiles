#!/bin/bash

VIDEO_DEV="/dev/video9"

sudo modprobe v4l2loopback devices=1 video_nr=9 card_label="Android_Webcam" exclusive_caps=1

adb wait-for-device
scrcpy --video-source=camera --camera-facing=back --camera-size=1920x1080 --v4l2-sink=$VIDEO_DEV --no-window --no-audio

sudo modprobe -r v4l2loopback
