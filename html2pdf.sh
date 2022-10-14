#!/usr/bin/env bash

if command -v wkhtmltopdf >/dev/null 2>&1; then
  if command -v parallel >/dev/null 2>&1; then
    parallel \
      wkhtmltopdf {} {.}.pdf \
      ::: "$@";
  else
    for f in "$@"; do
      wkhtmltopdf "$f" "${f%.[^.]*}".pdf
    done
  fi
elif command -v htmldoc > /dev/null 2>&1; then
  	if command -v parallel > /dev/null 2>&1; then
    	parallel \
				 htmldoc --cont --headfootsize 8.0 --linkcolor blue --linkstyle plain --format pdf14 {} > {.}.pdf \
      	::: "$@"
  	else
    	for f in "$@"; do
        htmldoc --cont --headfootsize 8.0 --linkcolor blue --linkstyle plain --format pdf14 --outfile "${f%.[^.]*}".pdf "$f" 
    	done
  	fi
else
  exit 1
fi

