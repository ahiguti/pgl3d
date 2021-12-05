#!/bin/bash

cd `dirname $0`

cp -af ../../ext/*.ttf ../res/ 2> /dev/null

cd ../source && \
  exec pxc -v=1 -gs -p=../unix/pxc_unsafe_debug.profile ./appmain.px $*
