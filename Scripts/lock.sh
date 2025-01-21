#!/bin/bash

TMPBG=/Downloads/screen.png
TMPBG2=/tmp/lock1.png
LOCK=/Downloads/lock.png
RES=$(xrandr | grep 'current' | sed -E 's/.*current\s([0-9]+)\sx\s([0-9]+).*/\1x\2/')
TIME=$(date +"%H\:%M")
ffmpeg -f x11grab -video_size $RES -y -i $DISPLAY -filter_complex "boxblur=7:1,overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2" -vframes 1 $TMPBG -loglevel quiet
#ffmpeg -i $TMPBG -vf "drawtext=text='$TIME':fontcolor=black:fontsize=60:x=915:y=500:" $TMPBG2 -loglevel quiet
#i3lock -i $HOME/$TMPBG2 -f -u 
i3lock -i $TMPBG -f -u 
rm $TMPBG
#rm $HOME/$TMPBG2
