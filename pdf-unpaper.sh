#!/usr/bin/env bash

# From https://github.com/SavvyBud/Dockerfile-unpaper/blob/cfb5ab986389dd1dbe70739839ac5c991de1a047/unpaper.sh

# exit on error or use of undeclared variable or pipe error:
set -o errtrace -o errexit -o nounset -o pipefail
# optionally debug output by supplying TRACE=1
[[ "${TRACE:-0}" == "1" ]] && set -o xtrace

shopt -s inherit_errexit
IFS=$'\n\t'
PS4='+\t '

error_handler() { echo "Error: In ${BASH_SOURCE[0]} Line ${1} exited with Status ${2}"; }
trap 'error_handler ${LINENO} $?' ERR

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo "Usage: $0"
    exit
fi

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
    cat <<EOF
pdf-unpaper - cleanses a scanned PDF
Usage:  pdf-unpaper <PDF file>
EOF
exit 0
fi

opts=
# opts="$opts --layout single --size a4 --input-pages 1 --output-pages 1"
# echo "Using unpaper options:"
# echo "$opts"

WD="$(pwd)"
trap 'cd "$WD"; rm -rf "$TMP"' INT TERM EXIT

TMP="$(mktemp -d)"
input="$1"
cp "$input" "$TMP"/

cd "$TMP" || exit 1

echo "Converting PDF file to PPM files..."
pdftoppm "$1" scan

echo "Renaming files for unpaper consumption..."
nmb=1
for i in ./scan*.ppm
do
  str="$(printf "%03d" $nmb)"
  if [ "$i" != "$str" ]; then
    mv "$i" "scan-$str.ppm"
  fi
  nmb=$((nmb + 1))
  echo "$i/scan-$str.ppm"
done

echo "Running unpaper..."
unpaper --verbose $opts scan-%03d.ppm unpaper-%03d.ppm
for i in unpaper*.ppm
do
  echo "Converting $i to ${i%%.ppm}.tiff..."
  ppm2tiff "$i" "${i%%.ppm}.tiff"
done
echo "Combining all TIFF files into all.tiff"
tiffcp ./*.tiff ./all.tiff
echo "Converting TIFF files back to a PDF file..."

output=./"${1%%.pdf}_unpaper.pdf"
tiff2pdf -z -o "$output" all.tiff
cp "$output" "$WD"/
