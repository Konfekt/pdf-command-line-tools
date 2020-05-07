The following command-line tools convert, optimize or search the passed PDF files in batches (speeding it up by [`GNU parallel`](https://www.gnu.org/software/parallel/) whenever available):

- `any2pdf.sh` : convert any type of documents into `PDF`s using [LibreOffice](https://www.libreoffice.org/download/download/)
- `html2pdf.sh` : convert `HTML` documents into `PDF`s using [`wkhtmltopdf`](https://wkhtmltopdf.org/)
- `md2pdf.sh` : convert `Markdown` documents into `PDF`s using [`pandoc`](https://pandoc.org/)
- `pdf-merge.sh` : merge multiple `PDF`s into a single `PDF` using `Ghostscript`
- `pdf-deflate.sh` : losslessly shrink `PDF`s using `Ghostscript`
- `pdf-sizeopt.sh` : losslessly shrink `PDF`s using [`pdfsizeopt`](https://github.com/pts/pdfsizeopt)
- `pdf-unpaper.sh` : polish scanned `PDF`s using [`unpaper`](https://github.com/unpaper/unpaper)
- `pdf-crop.sh` : crop the margins of `PDF`s using [`pdfCropMargins`](https://github.com/abarker/pdfCropMargins)
- `pdf-grep.sh` : search for text in `PDF`s (in parallel) using [`pdfgrep`](https://gitlab.com/pdfgrep/pdfgrep)
