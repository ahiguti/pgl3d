#!/bin/bash

cd `dirname $0`
drive="c:"
is_wsl=`uname -r | grep microsoft`
if [ "$is_wsl" != "" ]; then
  drive="/mnt/c"
fi

for plat in x64 ARM64; do
  for conf in Release Debug; do
    plcn="$plat/$conf"
    rm -rf "$plcn"
    mkdir -p "$plcn"
    cp -f $drive/build/SDL2/VisualC/$plcn/*.dll $plcn/
    cp -f $drive/build/SDL2_image/VisualC/$plcn/*.dll $plcn/
    cp -f $drive/build/SDL2_ttf/VisualC/$plcn/*.dll $plcn/
    cp -f $drive/build/glew/build/vc15/$plcn/*.dll $plcn/
  done
done
cp -f $drive/build/ftdi/*.dll x64/Release/
cp -f $drive/build/ftdi/*.dll x64/Debug/
cp -af $drive/build/ext/*.ttf ../res/

mkdir -p ARM64EC/Release
mkdir -p ARM64EC/Debug
cp -n x64/Release/* ARM64EC/Release/
cp -n x64/Debug/* ARM64EC/Debug/

mkdir -p ./gen/
cp -af $drive/build/imgui/imgui*.cpp ./gen/
cp -af $drive/build/imgui/imgui*.h ./gen/
cp -af $drive/build/imgui/backends/imgui_impl_sdl2.* ./gen/
cp -af $drive/build/imgui/backends/imgui_impl_opengl3*.* ./gen/

