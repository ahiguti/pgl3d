#!/bin/bash

# ビルドしてから実行する。ビルド時にエラーが出ると更新を待ちリビルドする。
# pxc.profile で container_guard=0 にしているので、デバッグするときは必ず
# debug build ですること

cd `dirname $0`

is_cygwin=`uname | cut -d '_' -f 1`
is_wsl=`uname -r | grep microsoft`

pxc_build_config=$PXC_BUILD_CONFIG
if [ "$pxc_build_config" == "" ]; then
        pxc_build_config=Release
fi

if [ "$is_cygwin" == "CYGWIN" -o "$is_wsl" != "" ]; then
        platform=windows
	build_target=./windows/x64/$pxc_build_config/pgl3d_app.exe
else
        platform=unix
	build_script=./unix/$pxc_build_config.sh
	build_target=./source/app.px.exe
fi

build_script=./$platform/$pxc_build_config.sh

echo "PXC_BUILD_CONFIG=$pxc_build_config"
echo "platform=$platform"
echo "build_target=$build_target"
echo "args=$*"

while true; do
	newer_files=`find ./source -name "*.px" -and -newercc \
		"$build_target" 2> /dev/null`
	files_0=`find ./source -name "*.px"`;
	stat_str_0=`stat -c "%z" $files_0 2> /dev/null`;
	if [ -e "$build_target" -a -z "$newer_files" ]; then
		echo "$build_target" is up to date 1>&2
		break
	else
		if "$build_script"; then
			break
		fi
	fi
        exit 1
	# ビルド失敗するとソースが更新されるまで待ち、
	# 更新されるとリビルドする <- やめ
	while true; do
		sleep 1
		files_1=`find ./source -name "*.px"`;
		stat_str_1=`stat -c "%z" $files_1 2> /dev/null`;
		if [ "$stat_str_0" != "$stat_str_1" ]; then
			break
		fi
	done
done

if [ "$PXC_BUILD_NOEXEC" != "" ]; then
        # PXC_BUILD_NOEXECが指定されていれば実行せずに終了する
        exit 0
fi

bgpid=""

wait_bgpid() {
        p="$bgpid"
        bgpid=""
        if [ "$p" != "" ]; then
                kill -9 "$p" > /dev/null 2>&1
                echo waiting $p ...
                wait "$p" > /dev/null 2>&1
                echo done
        fi
}

trap "echo got SIGINT" 2
trap "echo got SIGTERM" 15
trap wait_bgpid EXIT

echo > var/app.log
tail -f var/app.log &
bgpid=$!
"$build_target" $* > /dev/null 2>&1

