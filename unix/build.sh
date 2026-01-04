#!/bin/bash

cd "`dirname "$0"`"

mkdir -p ./gen/

# 注意: rsyncに-aを付けると更新がなくてもctimeを更新してしまう
rsync -c ../../ext/*.ttf ../res/
rsync -c ../../imgui/imgui*.cpp ./gen/
rsync -c ../../imgui/imgui*.h ./gen/
rsync -c ../../imgui/backends/imgui_impl_sdl2.* ./gen/
rsync -c ../../imgui/backends/imgui_impl_opengl3*.* ./gen/
rsync -c ../source/appmain.px ./gen/

if [ "$PGL3D_BUILD_PROFILE" = "" ]; then
  PGL3D_BUILD_PROFILE=release
fi
echo $0: PGL3D_BUILD_PROFILE=$PGL3D_BUILD_PROFILE

cd gen && \
  exec pxc -v=2 -p=../pxc_unsafe_${PGL3D_BUILD_PROFILE}.profile \
    -w=./build -ne -o=./appmain.exe ./appmain.px $*

