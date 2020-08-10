#!/bin/bash

cd `dirname $0`
drive="c:"
is_wsl=`uname -r | grep microsoft`
if [ "$is_wsl" != "" ]; then
	drive="/mnt/c"
fi
mkdir -p ./x64/Release
rm -f ./x64/Release/*.exe
cp -af $drive/build/ext/*.dll ./x64/Release/
cp -af $drive/build/ext/*.ttf ../res/

# chcp.com 65001
rm -f ./x64/Release/pgl3d_app.log
./pxc2cc-windows-release.sh && \
"$drive/Program Files (x86)/Microsoft Visual Studio/2019/Professional/Common7/IDE/devenv.exe" pgl3d_app.sln /Build "Release|x64"
ret=$?
if [ -f ./x64/Release/pgl3d_app.log ]; then
  cat ./x64/Release/pgl3d_app.log
fi
echo ret $ret
exit $ret
