#!/bin/bash

if [ "$PXC_BUILD_PROFILE" == "" ]; then
  PXC_BUILD_PROFILE=release
fi
echo $0: PXC_BUILD_PROFILE=$PXC_BUILD_PROFILE

cd `dirname $0` &&
  pushd ../source > /dev/null && \
  pxc -p=../windows/pxc_windows_${PXC_BUILD_PROFILE}.profile \
    --generate-single-cc -nb --generate-cc=../windows/gen/ \
    appmain.px && \
  popd > /dev/null

