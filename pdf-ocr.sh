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
  echo "OCR a bunch of PDFs. Usage: $0"
  exit
fi

ocrmypdfCmdArgs="--skip-text"
# these options more than double file size
# ocrmypdfCmdArgs="$ocrmypdfCmdArgs --deskew --clean-final --remove-vectors"

# if the new OCRed file size is bigger than this percentage times the
# old file size then keep the old file
threshold=200

# to avoid Profile file not available (tesseract_opencl_profile_devices.dat)
[ -f tesseract_opencl_profile_devices.dat ] || tesseract --list-langs

trap 'rm tesseract_opencl_profile_devices.dat' EXIT

fileext() {
    case "$1" in
        .*.*) extension=${1##*.} ;;
        .*) extension= ;;
        *.*) extension=${1##*.} ;;
    esac
    echo "$extension"
} && export -f fileext

args=("$@")
for arg in "${args[@]}"; do
    if [[ ! -f "$arg" ]]; then
        params+=("$arg")
        shift
    fi
done

for file in "$@"; do
    fileext="$(fileext "$file")"
    if [ "$fileext" != "pdf" ]; then
        echo "$file does not seem to be a PDF file. Exiting."
        return 1
    fi
    file_ocr="$file.ocr"
    echo "Processing $file ..."
    trap 'rm "$file_ocr"' EXIT
    ocrmypdf "${params[@]}" ${ocrmypdfCmdArgs} "$file" "$file_ocr"
    if [ $? -eq 0 ]; then
        old_size=$(stat --printf="%s" "$file")
        new_size=$(stat --printf="%s" "$file_ocr")
        percent=$((new_size * 100 / old_size))
        echo -n "New size: $percent%. "
        if [ $percent -gt $threshold ]; then
            echo "Keeping original."
            rm "$file_ocr"
        else
            echo "Replacing file."
            mv "$file_ocr" "$file"
        fi
    else
        echo "Error occurred. Keeping original."
        exit 1
    fi

done
