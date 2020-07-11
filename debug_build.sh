#!/bin/bash

cd `dirname $0`

exec env PXC_BUILD_CONFIG=Debug ./build_exec.sh $*

