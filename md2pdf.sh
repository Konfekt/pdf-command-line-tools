#!/usr/bin/env bash

command -v pandoc >/dev/null 2>&1 || exit 1

if [ $# -ge 2 ]; then
  if command -v parallel >/dev/null 2>&1; then
    parallel pandoc --standalone --from markdown --to latex --output {.}.pdf {} ::: "$@";
  else
    for f in "$@"; do
      pandoc --standalone --from markdown --to latex --output "${f%.[^.]*}".pdf "$f"
    done
  fi
else
  eval in_file=\${$#}
  if command -v latexrun >/dev/null 2>&1; then
    tex_file="${in_file%.[^.]*}".tex
    pandoc --standalone --from markdown --to latex --output "$tex_file" "$in_file" &&
	  latexrun "$in_file"
	else
    out_file="${in_file%.[^.]*}".pdf
    pandoc --standalone --from markdown --to latex --output "$out_file" "$in_file"
	fi
fi
