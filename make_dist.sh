#!/bin/bash

cd `dirname $0`

./clean_all.sh
if ! env PXC_BUILD_NOEXEC=1 ./build_exec.sh ; then
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

