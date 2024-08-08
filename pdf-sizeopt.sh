#!/usr/bin/env bash

# trace exit on error of program or pipe (or use of undeclared variable)
set -o errtrace -o errexit -o pipefail # -o nounset
# optionally debug output by supplying TRACE=1
[[ "${TRACE:-0}" == "1" ]] && set -o xtrace

shopt -s inherit_errexit
IFS=$'\n\t'
PS4='+\t '

[[ ! -t 0 ]] && [[ -n "$DISPLAY" ]] && command -v notify-send > /dev/null 2>&1 && notify=1

error_handler() {
  summary="Error: In ${BASH_SOURCE[0]}, Lines $1 and $2, Command $3 exited with Status $4"
  body=$(pr -tn "${BASH_SOURCE[0]}" | tail -n+$(($1 - 3)) | head -n7 | sed '4s/^\s*/>> /')
  echo >&2 -en "$summary\n$body" &&
    [ -n "${notify:+x}" ] && notify-send --critical "$summary" "$body"
  exit "$4"
}

trap 'error_handler $LINENO "$BASH_LINENO" "$BASH_COMMAND" $?' ERR

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
  echo "Compress PDFs using pdfsizeopt. Usage: $0"
  exit
fi

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
