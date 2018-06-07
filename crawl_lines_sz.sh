#!/bin/bash

# NOTE: This script should be run at 23:59, exploiting a strange bug that will
# respond with all lines at around 00:00.

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/sz/buses"
szkgdir="$basedir/szkg"
log_file="$szkgdir/logs"
all_latest_html="$szkgdir/all.latest.html"
all_latest_guid="$szkgdir/all.latest.guid"
date=$(date '+%Y%m%d')

for x in $(seq 1 360); do
  outfile="$szkgdir/$(date '+%H%M%S_%N')"
  wget -O "$outfile" 'http://www.szjt.gov.cn/Manager.aspx?PageGuid=bf6cf9f4-4e23-4bac-9ecd-062b859a820d'
  sleep 0.5
done

find "$szkgdir" \( -name '2359*' -or -name '000*' \) -type f -not -size +50k | xargs rm
all_html=$(find "$szkgdir" \( -name '2359*' -or -name '000*' \) -type f -size +50k -printf '%s\t%p\n' | sort -nr | head -n 1 | cut -f2)
if [[ -f "$all_html" ]]; then
  if ! cmp "$all_html" "$all_latest_html"; then
    logtime=$(date '+[%Y-%m-%d %H:%M:%S]')
    echo $logtime NEW VERSION: >> $log_file
    new_file="$szkgdir/all.$date"
    new_file="$szkgdir/all.20180605"
    mv "$all_html" "$new_file.html"
    grep option "$new_file.html" |
      sed 's|\s*<option [^>]*value="\([^"]*\)">\([^<]*\)\(</option>\)\?|\1\t\2|' |
      sed 's|</option>||' |
      sed 's|&gt;|>|' |
      tr -d '\n' |
      sed 's/\r/\n/g' |
      sed 's/ //g' |
      sort -k2 > "$new_file.guid"
    diff -u "$all_latest_guid" "$new_file.guid" | sed 's/^/'"$logtime"' DIFF /' >> $log_file
    echo "$logtime" STAT $(wc -l < "$all_latest_guid") lines '->' $(wc -l < "$new_file.guid") lines >> $log_file
    cp "$new_file.guid" "$all_latest_guid"
    cp "$new_file.html" "$all_latest_html"
  else
    echo `date '+[%Y-%m-%d %H:%M:%S]'` No update. >> $log_file
    rm "$all_html"
  fi
else
  echo `date '+[%Y-%m-%d %H:%M:%S]'` Page of all lines was not retrieved. >> $log_file
  rm $szkgdir/2359* $szkgdir/000*
fi
mv $szkgdir/2359* $szkgdir/000* "$szkgdir/misc"
