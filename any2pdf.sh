#!/bin/sh

if [ $# -ge 2 ] && command -v parallel >/dev/null 2>&1; then
  parallel libreoffice --convert-to pdf {} ::: "$@" 2>/dev/null;
else
  libreoffice --convert-to pdf "$@"
fi
