#!/bin/bash

cd `dirname $0`
dn=`pwd`
dnbase=`basename $dn`

if [ "$PGL3D_BUILD_PROFILE" = "" ]; then
  PGL3D_BUILD_PROFILE=release
fi
echo $0: PGL3D_BUILD_PROFILE=$PGL3D_BUILD_PROFILE

cd `dirname $0` &&
  pushd ../source > /dev/null && \
  pxc -v=1 -p=../$dnbase/pxc_windows_${PGL3D_BUILD_PROFILE}.profile \
    -w=../$dnbase/build -nb --generate-cc=../$dnbase/gen/ \
    appmain.px && \
  popd > /dev/null

# vc++がソースをutf-8と解釈するためにBOMを付ける
# メモ: コンパイラに /utf-8 と付ければBOMを付けなくてよいので現状そうしている。
#  ../add_bom.sh ../$dnbase/gen/*.cc
