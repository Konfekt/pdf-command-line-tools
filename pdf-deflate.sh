#!/usr/bin/env bash

# trace exit on error of program or pipe (or use of undeclared variable)
set -o errtrace -o errexit -o pipefail # -o nounset
# optionally debug output by supplying TRACE=1
[[ "${TRACE:-0}" == "1" ]] && set -o xtrace

shopt -s inherit_errexit
IFS=$'\n\t'
PS4='+\t '

if [[ ! -t 0 ]] && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v notify-send >/dev/null 2>&1; then
    notify=1
fi

error_handler() {
    local line=$1 command=$2 status=$3
    local script=${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}
    local start=$(( line > 3 ? line - 3 : 1 ))
    local end=$(( line + 3 ))
    local summary body

    trap - ERR
    set +o errexit +o pipefail

    summary="Error: In ${script}, line ${line}, command ${command@Q} exited with status ${status}"
    body=$(
        awk -v start="$start" -v end="$end" -v line="$line" '
            NR < start || NR > end { next }
            {
                prefix = (NR == line ? ">> " : "   ")
                printf "%s%5d  %s\n", prefix, NR, $0
            }
        ' "$script" 2>/dev/null
    )

    printf '%s\n' "$summary" >&2
    [[ -n "$body" ]] && printf '%s\n' "$body" >&2
    [[ -n "${notify:-}" ]] && notify-send --critical "$summary" "$body" >/dev/null 2>&1 || true

    exit "$status"
}

trap 'error_handler "$LINENO" "$BASH_COMMAND" "$?"' ERR

if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
# See http://www.alfredklomp.com/programming/shrinkpdf/
    echo "Compress PDFs using ps2pdf. Usage: $0 FILE..."
    exit 0
fi

if (( $# == 0 )); then
    echo "Compress PDFs using ps2pdf. Usage: $0 FILE..." >&2
    exit 1
fi

if ! command -v ps2pdf >/dev/null 2>&1; then
    echo "ps2pdf not found. Please install Ghostscript." >&2
    exit 127
fi

# percentage of the original size above which file is kept after compression
export threshold="${threshold:-80}"
# default > ebook > screen
export quality="${quality:-default}"

deflate() {
    local f=$1
    local ext=${f##*.}
    local fnew=$f.new
    local old_size new_size percent

    if [[ ! -f "$f" ]]; then
        printf '%s is not a file. Skipping.\n' "$f" >&2
        return 1
    fi

    if [[ "${ext,,}" != "pdf" ]]; then
        printf '%s does not seem to be a PDF file. Skipping.\n' "$f" >&2
        return 1
    fi

    rm -f -- "$fnew"
    printf 'Compressing %s ...\n' "$f"

    if ps2pdf \
        -q \
        -dPrinted=false -dPDFSETTINGS=/"$quality" -dCompatibilityLevel=1.4 \
        -dDetectDuplicateImages=true -dDownsampleColorImages=true \
        -dEmbedAllFonts=true -dSubsetFonts=true -dCompressFonts=true \
        -dAutoRotatePages=/None \
        "$f" "$fnew"
        # -dPDFACompatibilityPolicy=1 -dSimulateOverprint=true \
        # -dColorImageDownsampleType=/Bicubic -dColorImageResolution=72 \
        # -dGrayImageDownsampleType=/Bicubic -dGrayImageResolution=72 \
        # -dMonoImageDownsampleType=/Bicubic -dMonoImageResolution=72 \
    then
        old_size=$(wc -c <"$f")
        new_size=$(wc -c <"$fnew")

        if (( old_size == 0 )); then
            echo "Original file is empty. Keeping original." >&2
            rm -f -- "$fnew"
            return 1
        fi

        percent=$(( new_size * 100 / old_size ))
        printf 'New size: %s%%. ' "$percent"

        if (( percent > threshold )); then
            echo "Keeping original."
            rm -f -- "$fnew"
        else
            echo "Replacing file."
            mv -- "$fnew" "$f"
        fi
    else
        echo "Error occurred. Keeping original." >&2
        rm -f -- "$fnew"
        return 1
    fi
}
export -f deflate

status=0
if command -v parallel >/dev/null 2>&1; then
    parallel deflate {} ::: "$@" || status=$?
else
    for f in "$@"; do
        deflate "$f" || status=$?
    done
fi

exit "$status"
