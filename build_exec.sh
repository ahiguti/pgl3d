#!/bin/bash

# ビルドしてから実行する。ビルド時にエラーが出ると更新を待ちリビルドする。
# pxc.profile で container_guard=0 にしているので、デバッグするときは必ず
# debug build ですること

cd `dirname $0`

is_cygwin=`uname | cut -d '_' -f 1`
is_wsl=`uname -r | grep microsoft`

# pxcのdebug/releaseコンパイルの区別。pxcがdebugビルドでもc++
# はreleaseでコンパイルする。
pxc_build_config=$PXC_BUILD_CONFIG
if [ "$pxc_build_config" == "" ]; then
        pxc_build_config=release_build
fi

if [ "$is_cygwin" == "CYGWIN" -o "$is_wsl" != "" ]; then
	build_script=./windows/$pxc_build_config.sh
	build_target=./windows/x64/Release/pgl3d_demoapp.exe
else
	build_script=./unix/$pxc_build_config.sh
	build_target=./source/demoapp.px.exe
fi

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

bgpid=""

trap "echo got SIGINT && kill -9 $bdpid > /dev/null 2>&1" 2
trap "echo got SIGTERM && kill -9 $bdpid > /dev/null 2>&1" 15

echo > var/demoapp.log
tail -f var/demoapp.log &
bgpid=$!
"$build_target" $* > /dev/null 2>&1
kill -9 "$bgpid" > /dev/null 2>&1
wait "$bgpid" > /dev/null 2>&1

