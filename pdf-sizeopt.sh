#!/usr/bin/env bash
#
# exit on error or use of undeclared variable: set -eu
set -o errtrace -o nounset
#
# Compress PDFs using pdfsizeopt.

# percentage of the original size above which file is kept after compression
export threshold=90

sizeopt() {
    f="$1"
    fnew="$f.new"
    echo "Compressing $f ..."
    pdfsizeopt --use-pngout=no --use-image-optimizer=optipng "$f" "$fnew"
    old_size=$(stat --printf="%s" "$f")
    new_size=$(stat --printf="%s" "$fnew")
    percent=$((new_size * 100 / old_size))
    echo -n "New size: $percent%. "

    if [ $percent -gt $threshold ]; then
        echo "Keeping original."
        rm "$fnew"
        return
    else
        echo "Replacing file."
        mv "$fnew" "$f"
    fi
} && export -f sizeopt

if command -v parallel >/dev/null 2>&1; then
    parallel sizeopt {} ::: "$@"
else
  for f in "$@"; do
    sizeopt "$f"
  done
fi
