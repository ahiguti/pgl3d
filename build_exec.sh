#!/bin/bash

# ビルドしてから実行する。ビルド時にエラーが出ると更新を待ちリビルドする。
# releaseビルドでもcontainer_guardとbounds_checkingを有効にしている。
# PGL3D_BUILD_PROFILE=release_distとすると境界チェック等を無効化してビルド
# する。

cd `dirname $0`

is_cygwin=`uname | cut -d '_' -f 1`
is_wsl=`uname -r | grep microsoft`

if [ "$PGL3D_BUILD_CONFIG" = "" ]; then
        PGL3D_BUILD_CONFIG=Release
fi
if [ "$PGL3D_BUILD_PROFILE" = "" ]; then
        PGL3D_BUILD_PROFILE=release
        #PGL3D_BUILD_PROFILE=release_dist
        #PGL3D_BUILD_PROFILE=debug
fi
if [ "$PGL3D_BUILD_ARCH" = "" ]; then
	PGL3D_BUILD_ARCH=x64
fi

if [ "$PGL3D_BUILD_PLATFORM" != "" ]; then
        platform="$PGL3D_BUILD_PLATFORM"
elif [ "$is_cygwin" = "CYGWIN" -o "$is_wsl" != "" ]; then
        platform=windows_v142
else
        platform=unix
fi

if [ "$platform" = "unix" ]; then
	build_target=./$platform/gen/appmain.exe
else
	build_target=./$platform/$PGL3D_BUILD_ARCH/$PGL3D_BUILD_CONFIG/pgl3d_app.exe
fi

build_script=./$platform/build.sh

echo "$0: PGL3D_BUILD_CONFIG=$PGL3D_BUILD_CONFIG"
echo "$0: PGL3D_BUILD_PROFILE=$PGL3D_BUILD_PROFILE"
echo "$0: PGL3D_BUILD_PLATFORM=$PGL3D_BUILD_PLATFORM"
echo "$0: platform=$platform"
echo "$0: build_target=$build_target"
echo "$0: args=$*"

newer_files=`find ./source -name "*.px" -and -newercc \
        "$build_target" 2> /dev/null`
files_0=`find ./source -name "*.px" -o -name "*.pxi"`;
stat_str_0=`stat -c "%z" $files_0 2> /dev/null`;
if [ -e "$build_target" -a -z "$newer_files" ]; then
        echo "$build_target" is up to date 1>&2
else
        if ! "$build_script"; then
                echo "nonzero status: $build_script"
                exit 1
        fi
fi

chmod 755 "$build_target" # WSLだと実行権限をつける必要がある

if [ "$PGL3D_BUILD_NOEXEC" != "" ]; then
        # PGL3D_BUILD_NOEXECが指定されていれば実行せずに終了する
        exit 0
fi

bgpid=""

wait_bgpid() {
        p="$bgpid"
        bgpid=""
        if [ "$p" != "" ]; then
                kill "$p" > /dev/null 2>&1
                echo waiting $p ...
                wait "$p"
                echo wait "$p" done
        fi
}

trap wait_bgpid EXIT

unset TZ # cygwinがTZをセットしてしまうので消す
echo > var/app.log
tail -F var/app.log &
bgpid=$!
"$build_target" $* > /dev/null 2>&1

