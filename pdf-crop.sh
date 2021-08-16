#!/usr/bin/env bash

command -v pdf-crop-margins >/dev/null 2>&1 || exit 1

pdfcrop="pdf-crop-margins --gsFix --percentRetain 1"
if command -v parallel >/dev/null 2>&1; then
  parallel $pdfcrop {} ::: "$@"
else
  for f in "$@"; do
    $pdfcrop "$f"
  done
fi
