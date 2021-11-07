#!/bin/bash

# 大きなテクスチャサイズを指定して実行する。

cd `dirname $0`
exec ./build_exec.sh ./res/pgl3d-large.cnf $*

