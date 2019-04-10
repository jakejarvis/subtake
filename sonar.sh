#!/bin/bash
# Usage : ./sonar.sh <version number> <file>
# Example: ./sonar.sh 2018-10-27-1540655191-fdns_cname.json.gz sonar.txt


mkdir /tmp/sonar

# Gathering data from scans.io / Rapid7 Project Sonar if not already provided
# Find the latest filename listed at https://opendata.rapid7.com/sonar.fdns_v2/ ending with fdns_cname.json.gz and pass in as first argument
# Example: 2018-10-27-1540655191-fdns_cname.json.gz
if [ ! -f $1 ]; then
  echo "Downloading $1, this may take a while..."
  wget -q -O /tmp/sonar/$1 https://opendata.rapid7.com/sonar.fdns_v2/$1
  echo "Finished downloading $1."
fi


# Parsing data into a temp file called sonar_cnames
echo "Grepping for CNAME records..."
zcat < $1 | grep 'type":"cname' | awk -F'":"' '{print $3, $5}' | \
  awk -F'"' '{print $1, $3}' | sed -e s/" type "/" "/g >> /tmp/sonar/sonar_cnames
echo "CNAME records grepped."


# List of fingerprints we're going to grep for
declare -a prints=(
  "\.s3-website"
  "\.s3.amazonaws.com$"
  "\.herokuapp.com$"
  "\.herokudns.com$"
#  "\.wordpress.com$"
  "\.pantheonsite.io$"
  "domains.tumblr.com$"
  "\.zendesk.com$"
  "\.github.com$"
  "\.github.io$"
  "\.global.fastly.net$"
  "\.ghost.io$"
#  "\.myshopify.com$"
  "\.surge.sh$"
  "\.bitbucket.io$"
  "\.azurewebsites.net$"
  "\.cloudapp.net$"
  "\.trafficmanager.net$"
  "\.blob.core.windows.net$"
)


# Grepping CNAMEs w/ matching fingerprints from the array
echo "Grepping for fingerprints..."
grep -Ei $(echo ${prints[@]}|tr " " "|") /tmp/sonar/sonar_cnames >> /tmp/sonar/sonar_prints
echo "Fingerprints grepped."


# Output only the CNAME (not the fingerprint)
echo "Sorting CNAME records..."
cat /tmp/sonar/sonar_prints | awk '{print $1}' >> /tmp/sonar/sonar_records
echo "CNAME records sorted."


# Removing recursive records
echo "Removing recursive records..."
grep -v -Ei $(echo ${prints[@]}|tr " " "|") /tmp/sonar/sonar_records >> $2
echo "Removed recursive records."


# Remove temp files
echo "Cleaning up..."
rm -rf /tmp/sonar
rm $1
echo "Cleaned up."


echo "[+] Finished!"
