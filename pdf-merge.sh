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
  echo "Merge PDFs using gs (Ghostscript). Usage: $0"
  exit
fi

# default > ebook > screen
quality="default"

if [ -f "$1" ]; then
  file="$(realpath "$1")"
  parent="${file%/*}"
  dir="${parent##*/}"
else
  echo "pdfmerge: merge pdf files"
  echo "usage: pdfmerge <files>"
  echo "Please specify files."
  exit
fi

if [ -f "$dir".pdf ]; then
  dir=$(mktemp --dry-run "./${dir}_XXX")
fi

gs -sDEVICE=pdfwrite \
  -q -dNOPAUSE -dBATCH -dSAFER \
  -dPrinted=false -dPDFSETTINGS=/$quality -dCompatibilityLevel=1.4 \
  -dDetectDuplicateImages -dDownsampleColorImages=true \
  -dEmbedAllFonts=true -dSubsetFonts=true -dCompressFonts=true \
  -dAutoRotatePages=/None \
  -sOutputFile="$dir".pdf "$@"
