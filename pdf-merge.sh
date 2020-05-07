#!/usr/bin/env sh
#
# exit on error or use of undeclared variable: set -eu
set -o errtrace -o nounset
#
# Merge PDFs using gs.

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
