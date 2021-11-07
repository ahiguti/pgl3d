#!/bin/bash

# テクスチャ編集モードで実行する。

cd `dirname $0`
exec ./build_exec.sh ./res/pgl3d-edit.cnf $*
#exec ./debug_build.sh ./res/pgl3d-edit.cnf $*
