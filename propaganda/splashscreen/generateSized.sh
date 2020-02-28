#!/bin/bash

#
# Convert full screen image to different resolutions
# @see https://material.io/resources/devices/
#

src='splash.png'
toDir='/home/jaja/wqz/prog/android/ognCubeControl/android/app/src/main/res'

# xxxhdpi 
convert $src -resize 1440x2560 temp.png
mv temp.png $toDir/mipmap-xxxhdpi/$src

# xxhdpi 
convert $src -resize 1080x1920 temp.png
mv temp.png $toDir/mipmap-xxhdpi/$src

# xhdpi 
convert $src -resize 720x1280 temp.png
mv temp.png $toDir/mipmap-xhdpi/$src

# mdpi 
convert $src -resize 768x1024 temp.png
mv temp.png $toDir/mipmap-mdpi/$src

# hdpi
convert $src -resize 320x320 temp.png
mv temp.png $toDir/mipmap-hdpi/$src

