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
  pxc -p=../$dnbase/pxc_windows_${PGL3D_BUILD_PROFILE}.profile \
    --generate-single-cc -nb --generate-cc=../$dnbase/gen/ \
    appmain.px && \
  popd > /dev/null

