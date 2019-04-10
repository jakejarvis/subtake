#!/bin/bash
# Usage : ./sonar.sh <version number> <file>
# Example: ./sonar.sh 2018-10-27-1540655191 sonar.txt

set -u

# DEBUG: Mark start time
time_start=$(date -u +%s)

# Set location for temporary junk
tempdir=/tmp/sonar

# Make sure there aren't existing temp files
rm -rf ${tempdir:?}
mkdir -p $tempdir


# Download dataset from Rapid7 if not already provided
# Find the latest timestamp listed at https://opendata.rapid7.com/sonar.fdns_v2/ (the string preceding "-fdns_cname.json.gz") and pass in as first argument
# Example: 2018-10-27-1540655191
filename="$1-fdns_cname.json.gz"
if [ ! -f "$tempdir/$filename" ]; then
  SECONDS=0
  echo "[-] Downloading $filename from Rapid7..."
  curl -#Lo "$tempdir/$filename" "https://opendata.rapid7.com/sonar.fdns_v2/$filename"
  echo "[+] Successfully downloaded $filename. Took $((SECONDS/60)) minutes."
fi


# Parse data into a temp file called sonar_cnames
SECONDS=0
echo "[-] Extracting CNAME records..."
zcat < "$tempdir/$filename" | grep 'type":"cname' | awk -F'":"' '{print $3, $5}' | \
  awk -F'"' '{print $1, $3}' | sed -e s/" type "/" "/g > $tempdir/sonar_cnames
rm "${tempdir:?}/$filename"
echo "[+] CNAME records extracted. Took $((SECONDS/60)) minutes."


# List of fingerprints we're going to grep for
declare -a prints=(
  "\.s3-website"
  "\.s3.amazonaws.com$"
  "\.herokuapp.com$"
  "\.herokudns.com$"
  "\.wordpress.com$"
  "\.pantheonsite.io$"
  "domains.tumblr.com$"
  "\.zendesk.com$"
  "\.github.com$"
  "\.github.io$"
  "\.global.fastly.net$"
  "\.ghost.io$"
  "\.myshopify.com$"
  "\.surge.sh$"
  "\.bitbucket.io$"
  "\.azurewebsites.net$"
  "\.cloudapp.net$"
  "\.trafficmanager.net$"
  "\.blob.core.windows.net$"
)

prints_array=$(echo "${prints[@]}" | tr ' ' '|')


# Grepping CNAMEs w/ matching fingerprints from the array
echo "[-] Dusting for fingerprints..."
SECONDS=0
grep -Ei "$prints_array" $tempdir/sonar_cnames > $tempdir/sonar_prints
rm ${tempdir:?}/sonar_cnames
echo "[+] Fingerprints dusted. Took $((SECONDS/60)) minutes."


# Output only the CNAME (not the target/fingerprint)
echo "[-] Isolating CNAME records..."
SECONDS=0
awk '{print $1}' $tempdir/sonar_prints > $tempdir/sonar_records
rm ${tempdir:?}/sonar_prints
echo "[+] CNAME records isloated. Took $((SECONDS/60)) minutes."


# Removing recursive records (when CNAME contains its own fingerprint; ex: abcd.herokuapp.com -> us-east-1-a.route.herokuapp.com)
echo "[-] Removing recursive records..."
SECONDS=0
grep -v -Ei "$prints_array" $tempdir/sonar_records > "$2"
rm ${tempdir:?}/sonar_records
echo "[+] Recursive records removed. Took $((SECONDS/60)) minutes."


# All done with temp files, make sure we've tidied everything up
echo "[-] Cleaning up..."
rm -rf ${tempdir:?}
echo "[+] Cleaned up."


# DEBUG: Mark finish time
time_end=$(date -u +%s)


echo "[+] Finally done! Took $(((time_end-time_start)/60)) minutes total."
