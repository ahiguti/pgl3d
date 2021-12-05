#!/bin/bash

cd `dirname $0`
drive="c:"
is_wsl=`uname -r | grep microsoft`
if [ "$is_wsl" != "" ]; then
	drive="/mnt/c"
fi
mkdir -p ./x64/Debug
rm -f ./x64/Debug/*.exe
cp -af $drive/build/ext/*.dll ./x64/Debug/
cp -af $drive/build/ext/*.ttf ../res/

# chcp.com 65001
time ./pxc2cc-windows-debug.sh && \
time "$drive/Program Files (x86)/Microsoft Visual Studio/2019/Professional/Common7/IDE/devenv.exe" pgl3d_app.sln /Build "Debug|x64"
ret=$?
cat ./x64/Debug/pgl3d_app.log
exit $ret
