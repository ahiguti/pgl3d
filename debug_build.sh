#!/bin/bash

cd `dirname $0`

exec env PGL3D_BUILD_CONFIG=Debug ./build_exec.sh $*

