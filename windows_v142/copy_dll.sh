#!/bin/bash

cd `dirname $0`
drive="/cygdrive/c"
is_wsl=`uname -r | grep microsoft`
if [ "$is_wsl" != "" ]; then
  drive="/mnt/c"
fi

for plat in x64 ARM64; do
  for conf in Release Debug; do
    plcn="$plat/$conf"
    mkdir -p "$plcn"
    rsync -c $drive/build/SDL2/VisualC/$plcn/*.dll $plcn/
    rsync -c $drive/build/SDL2_image/VisualC/$plcn/*.dll $plcn/
    rsync -c $drive/build/SDL2_ttf/VisualC/$plcn/*.dll $plcn/
    rsync -c $drive/build/glew/build/vc15/$plcn/*.dll $plcn/
  done
done
rsync -c $drive/build/ftdi/*.dll x64/Release/
rsync -c $drive/build/ftdi/*.dll x64/Debug/
rsync -c $drive/build/ext/*.ttf ../res/

mkdir -p ./gen/
rsync -c $drive/build/imgui/imgui*.cpp ./gen/
rsync -c $drive/build/imgui/imgui*.h ./gen/
rsync -c $drive/build/imgui/backends/imgui_impl_sdl2.* ./gen/
rsync -c $drive/build/imgui/backends/imgui_impl_opengl3*.* ./gen/

