#!/bin/bash
cd `dirname $0`
mkdir -p ./x64/Release
rm -f ./x64/Release/*.exe
cp -af c:/build/ext/*.dll ./x64/Release/
cp -af c:/build/ext/*.ttf ../res/
# chcp.com 65001
./pxc2cc-windows.sh && \
"C:/Program Files (x86)/Microsoft Visual Studio/2019/Professional/Common7/IDE/devenv.exe" pgl3d_demoapp.sln /Build "Release|x64"
ret=$?
cat ./x64/Release/pgl3d_demoapp.log
exit $ret
