#!/bin/bash

cd `dirname $0`

./copy_dll.sh

drive="c:"
is_wsl=`uname -r | grep microsoft`
if [ "$is_wsl" != "" ]; then
	drive="/mnt/c"
fi

barch=$PGL3D_BUILD_ARCH
if [ "$barch" = "" ]; then barch="x64"; fi
bconf=$PGL3D_BUILD_CONFIG
if [ "$bconf" = "" ]; then bconf="Release"; fi

echo "$0: conf_arch = $bconf|$barch"

# chcp.com 65001
rm -f ./$barch/$bconf/pgl3d_app.log
time ./pxc2cc-windows.sh && \
time "$drive/Program Files/Microsoft Visual Studio/2022/Preview/Common7/IDE/devenv.exe" pgl3d_app.sln /Build "$bconf|$barch"
ret=$?
if [ -f ./$barch/$bconf/pgl3d_app.log ]; then
  cat ./$barch/$bconf/pgl3d_app.log
fi
echo ret $ret
exit $ret
