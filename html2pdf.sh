#!/usr/bin/env bash

command -v wkhtmltopdf >/dev/null 2>&1 || exit 1

if command -v parallel >/dev/null 2>&1; then
  parallel \
    wkhtmltopdf {} {.}.pdf \
    ::: "$@";
else
  for f in "$@"; do
    wkhtmltopdf "$f" "${f%.[^.]*}".pdf
  done
fi
