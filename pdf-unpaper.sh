#!/usr/bin/env bash

# From https://github.com/SavvyBud/Dockerfile-unpaper/blob/cfb5ab986389dd1dbe70739839ac5c991de1a047/unpaper.sh

#!/usr/bin/env bash

# trace exit on error of program or pipe (or use of undeclared variable)
set -o errtrace -o errexit -o pipefail # -o nounset
# optionally debug output by supplying TRACE=1
[[ "${TRACE:-0}" == "1" ]] && set -o xtrace

shopt -s inherit_errexit
IFS=$'\n\t'
PS4='+\t '

[[ ! -t 0 ]] && [[ -n "$DISPLAY" ]] && command -v notify-send > /dev/null 2>&1 && notify=1

error_handler() {
  summary="Error: In ${BASH_SOURCE[0]}, Lines $1 and $2, Command $3 exited with Status $4"
  body=$(pr -tn "${BASH_SOURCE[0]}" | tail -n+$(($1 - 3)) | head -n7 | sed '4s/^\s*/>> /')
  echo >&2 -en "$summary\n$body" &&
    [ -n "${notify:+x}" ] && notify-send --critical "$summary" "$body"
  exit "$4"
}

trap 'error_handler $LINENO "$BASH_LINENO" "$BASH_COMMAND" $?' ERR

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
  echo "Polish scanned PDFs using unpaper. Usage: $0"
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
