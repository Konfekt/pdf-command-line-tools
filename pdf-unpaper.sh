#!/usr/bin/env sh 

# From https://github.com/SavvyBud/Dockerfile-unpaper/blob/cfb5ab986389dd1dbe70739839ac5c991de1a047/unpaper.sh

if ! { [ $# -eq 1 ] && [ -f "$1" ]; }; then
	cat <<HERE 
	pdf-unpaper - cleanses a scanned monochrome PDF 
	Usage:  pdf-unpaper <PDF file>
HERE
	exit 0;
fi

opts="-t pbm --overwrite -gs 5,5 -gp 5,5 -gt 0.5"
# opts="$opts --layout single --size a4 --input-pages 1 --output-pages 1"
echo "Using unpaper options:"
echo "$opts"
echo "Converting PDF file to PPM files..."
pdftoppm -mono "$1" scan

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
tiff2pdf -z -o ./"${1%%.pdf}_unpaper.pdf" all.tiff 
rm --force ./*.tiff
rm --force ./scan*.ppm
rm --force ./unpaper*.ppm
#rm $1
