#!/usr/bin/env bash

command -v pandoc >/dev/null 2>&1 || exit 1

if [ $# -eq 0 ]; then
  echo "usage: ${0} <file> ..."
  return 2
fi

case "${1}" in
  (*.md) from=markdown ;;
  (*.txt) from=markdown ;;
  (*.epub) from=epub ;;
  (*.odt) from=odt ;;
  (*.docx) from=docx ;;
  (*) echo "${0}: only accepts input file extensions txt,md,epub,odt,docx" ;;
esac

if [ $# -eq 1 ]; then
  eval in_file=\${$#}
  if command -v latexrun >/dev/null 2>&1; then
    tex_file="${in_file%.[^.]*}".tex
    pandoc --standalone --from $from --to latex --output "$tex_file" "$in_file" &&
	  latexrun "$in_file"
	else
    out_file="${in_file%.[^.]*}".pdf
    pandoc --standalone --from $from --to latex --output "$out_file" "$in_file"
	fi
else
  if command -v parallel >/dev/null 2>&1; then
    parallel pandoc --standalone --from $from --to latex --output {.}.pdf {} ::: "$@";
  else
    for f in "$@"; do
      pandoc --standalone --from $from --to latex --output "${f%.[^.]*}".pdf "$f"
    done
  fi
fi

