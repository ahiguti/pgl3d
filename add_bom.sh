#!/bin/bash

sdir="`dirname $0`"
bom=`echo -n -e '\xEF\xBB\xBF'`

for i in $@; do
        if [ ! -f "$i" -o -h "$i" ]; then
                echo "skip $i" >&2
                continue
        fi
        hd=`head -c 3 "$i"`
        if [ "$hd" != "$bom" ]; then
                echo "add bom $i" >&2
                echo -n "$bom" | cat - "$i" > "$i.tmp"
                mv "$i.tmp" "$i"
        else
                echo "has bom $i" >&2
        fi
done
