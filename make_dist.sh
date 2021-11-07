#!/bin/bash

# release_distでビルドし、実行に必要なdll等をdist/以下にコピーする。

cd `dirname $0`

./clean_all.sh
export PXC_BUILD_NOEXEC=1
export PXC_BUILD_PROFILE=release_dist
export PXC_BUILD_CONFIG=Release
if ! ./build_exec.sh ; then
        echo "build failed"
        exit 1
fi

rm -rf dist
mkdir dist
mkdir dist/var
cp -a res dist/
cp ./windows/x64/Release/pgl3d_app.exe dist/
cp -a ./windows/x64/Release/*.dll dist/
echo "done"

