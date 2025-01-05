#!/bin/bash

# platformをunixに指定してビルドする。
# WSL上でLinux版をビルドしたいときに使う。

exec env PGL3D_BUILD_PLATFORM=unix ./build_exec.sh $@
