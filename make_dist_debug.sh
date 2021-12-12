#!/bin/bash

# release_distでビルドし、実行に必要なdll等をpgl3d_dist/以下にコピーする。

cd `dirname $0`

./clean_all.sh
export PXC_BUILD_NOEXEC=1
export PXC_BUILD_PROFILE=release_dist
export PXC_BUILD_CONFIG=Debug
if ! ./build_exec.sh ; then
        echo "build failed"
        exit 1
fi

rm -rf pgl3d_dist
mkdir pgl3d_dist
mkdir pgl3d_dist/var
cp -a res pgl3d_dist/
cp ./windows/x64/Debug/pgl3d_app.exe pgl3d_dist/
cp -a ./windows/x64/Debug/*.dll pgl3d_dist/
echo "datadir=./data" > pgl3d_dist/res/pgl3d.cnf
cat res/pgl3d.cnf | grep -v 'datadir' >> pgl3d_dist/res/pgl3d.cnf
mkdir pgl3d_dist/data
# cygwin
cp /cygdrive/c/build/*.raw pgl3d_dist/data/
zip -r pgl3d_dist_debug.zip pgl3d_dist
echo "done"

