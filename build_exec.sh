#!/bin/bash

# ビルドしてから実行する。ビルド時にエラーが出ると更新を待ちリビルドする。
# releaseビルドでもcontainer_guardとbounds_checkingを有効にしている。
# would_invalidateとinvalid_indexが投げられることが無いならそれらを
# 無効にすることができるので、PXC_BUILD_PROFILE=release_distにする。

cd `dirname $0`

is_cygwin=`uname | cut -d '_' -f 1`
is_wsl=`uname -r | grep microsoft`

if [ "$PXC_BUILD_CONFIG" == "" ]; then
        PXC_BUILD_CONFIG=Release
fi
if [ "$PXC_BUILD_PROFILE" == "" ]; then
        PXC_BUILD_PROFILE=release
        #PXC_BUILD_PROFILE=release_dist
fi

if [ "$is_cygwin" == "CYGWIN" -o "$is_wsl" != "" ]; then
        platform=windows
	build_target=./windows/x64/$PXC_BUILD_CONFIG/pgl3d_app.exe
else
        platform=unix
	build_script=./unix/$PXC_BUILD_CONFIG.sh
	build_target=./source/appmain.px.exe
fi

build_script=./$platform/$PXC_BUILD_CONFIG.sh

echo "$0: PXC_BUILD_CONFIG=$PXC_BUILD_CONFIG"
echo "$0: PXC_BUILD_PROFILE=$PXC_BUILD_PROFILE"
echo "$0: platform=$platform"
echo "$0: build_target=$build_target"
echo "$0: args=$*"

newer_files=`find ./source -name "*.px" -and -newercc \
        "$build_target" 2> /dev/null`
files_0=`find ./source -name "*.px"`;
stat_str_0=`stat -c "%z" $files_0 2> /dev/null`;
if [ -e "$build_target" -a -z "$newer_files" ]; then
        echo "$build_target" is up to date 1>&2
else
        if ! "$build_script"; then
                echo "nonzero status: $build_script"
                exit 1
        fi
fi

if [ "$PXC_BUILD_NOEXEC" != "" ]; then
        # PXC_BUILD_NOEXECが指定されていれば実行せずに終了する
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

#trap "echo got SIGINT" 2
#trap "echo got SIGTERM" 15
trap wait_bgpid EXIT

unset TZ # cygwinがTZをセットしてしまうので消す
echo > var/app.log
tail -F var/app.log &
bgpid=$!
"$build_target" $* > /dev/null 2>&1

