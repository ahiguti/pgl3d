#!/bin/bash

cd `dirname $0`
./android/clean_all.sh
./windows_v142/clean_all.sh
./unix/clean_all.sh
rm -rf ./ios/gen/*
rm -rf ./emscripten/gen/*
rm -rf `find ./ios/ -name project.xcworkspace`
rm -rf `find ./ios/ -name xcuserdata`
rm -rf `find . -name .DS_Store`
rm -f source/*.exe source/*.o source/*.cc
rm -f res/*.ttf
rm -f var/*.raw var/*.log
rm -f glprog.*.bin
rm -f *.zip
rm -rf pgl3d_dist/
rm -f imgui.ini
