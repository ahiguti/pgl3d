#!/bin/bash

cd `dirname $0`
cd ../source

if ! [ -f ../res/mplus-1m-bold.ttf ]; then
  #cp -f /usr/share/fonts/mplus/mplus-1m-bold.ttf .
  cp -f /usr/share/fonts/truetype/mplus/mplus-1m-bold.ttf ../res/
fi

pxc -p=../emscripten/pxc_emscripten.profile --generate-single-cc -nb \
    --generate-cc=../emscripten/gen/ \
    appmain.px && \
if [ "$?" != "0" ]; then
    exit 1
fi
cd ..
  em++ -std=c++11 -O2 -I./emscripten/ \
    -s USE_SDL=2 -s USE_SDL_IMAGE=2 -s USE_SDL_TTF=2 -s USE_FREETYPE=1 \
    -s USE_BULLET=1 -s TOTAL_MEMORY=200mb \
    -s -s MAX_WEBGL_VERSION=2 \
    -s EXPORTED_FUNCTIONS="['_main','_load_fs_cb','_save_fs_cb']" \
    -Wno-tautological-compare \
    ./emscripten/gen/appmain.px.cc -o ./emscripten/gen/appmain.html \
    --preload-file res/dpat.png \
    --preload-file res/pmpat.png \
    --preload-file res/cube_right1.png \
    --preload-file res/cube_left2.png \
    --preload-file res/cube_top3.png \
    --preload-file res/cube_bottom4.png \
    --preload-file res/cube_front5.png \
    --preload-file res/cube_back6.png \
    --preload-file res/mplus-1m-bold.ttf \
    --preload-file res/pgl3d.cnf \
    --preload-file res/default-color.png \
    --preload-file res/default-depth.png \
    -lidbfs.js --emrun &&
  emrun --browser=firefox ./emscripten/gen/appmain.html 2>&1 | tee /tmp/z

