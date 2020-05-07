#!/bin/sh

if [ $# -ge 2 ] && command -v parallel >/dev/null 2>&1; then
  parallel --quote pdfgrep --with-filename --page-number --perl-regexp --color never "$1" {} ::: "${@:2}" 2>/dev/null;
else
  pdfgrep --with-filename --page-number --perl-regexp "$@"
fi
