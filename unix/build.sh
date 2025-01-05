#!/bin/bash

cd `dirname $0`

cp -af ../../ext/*.ttf ../res/ 2> /dev/null
mkdir -p ./gen/
cp -af ../../imgui/imgui*.cpp ./gen/
cp -af ../../imgui/imgui*.h ./gen/
cp -af ../../imgui/backends/imgui_impl_sdl2.* ./gen/
cp -af ../../imgui/backends/imgui_impl_opengl3*.* ./gen/
cp ../source/appmain.px ./gen/

if [ "$PGL3D_BUILD_PROFILE" = "" ]; then
  PGL3D_BUILD_PROFILE=release
fi
echo $0: PGL3D_BUILD_PROFILE=$PGL3D_BUILD_PROFILE

cd gen && \
  exec pxc -v=1 -gs -p=../pxc_unsafe_${PGL3D_BUILD_PROFILE}.profile \
    ./appmain.px $*

