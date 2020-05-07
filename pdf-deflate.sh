#!/bin/sh
#
# exit on error or use of undeclared variable: set -eu
set -o errtrace -o nounset
#
# Compress PDFs using ps2pdf.
# See http://www.alfredklomp.com/programming/shrinkpdf/

# percentage of the original size above which file is kept after compression
export threshold=80
# default > ebook > screen 
export quality="default"

deflate() {
    f="$1"
    fnew="$f.new"
    echo "Compressing $f ..."
    ps2pdf \
        -q -dNOPAUSE -dBATCH -dSAFER \
        -dPrinted=false -dPDFSETTINGS=/$quality -dCompatibilityLevel=1.4 \
        -dDetectDuplicateImages=true -dDownsampleColorImages=true \
        -dEmbedAllFonts=true -dSubsetFonts=true -dCompressFonts=true \
        -dAutoRotatePages=/None \
        "$f" "$fnew"
        # -dPDFACompatibilityPolicy=1 -dSimulateOverprint=true \
        # -dColorImageDownsampleType=/Bicubic -dColorImageResolution=72 \
        # -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=72 \
        # -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=72 \
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
} && export -f deflate

if command -v parallel >/dev/null 2>&1; then
    parallel deflate {} ::: "$@"
else
  for f in "$@"; do
    deflate "$f"
  done
fi
