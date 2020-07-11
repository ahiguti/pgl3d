#!/bin/bash

cd `dirname $0` &&
  pushd ../source > /dev/null && \
  pxc -p=../windows/pxc_windows.profile --generate-single-cc -nb \
	--generate-cc=../windows/gen/ \
	appmain.px && \
  popd > /dev/null

