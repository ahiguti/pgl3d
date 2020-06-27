#!/bin/bash

cd `dirname $0`
exec ./build_exec.sh ./res/pgl3d-edit.cnf $*
