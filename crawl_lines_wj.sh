#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/wj/"
log_file="$basedir/logs"
guid_file="$basedir/all.guid"
stops_file="$basedir/stops.map"
runtimes_file="$basedir/runtimes.map"
linesdir="$basedir/lines"
latest_lines="$linesdir/latest.json"
current_lines="$linesdir/current.json"
latest_details="$linesdir/latest_details.json"
current_details="$linesdir/current_details.json"

if wget -q -O "$latest_lines" "http://www.wjgjw.net/busSearch/data_mobile.php"; then
  if ! diff "$current_lines" "$latest_lines" > /dev/null; then
    cp "$latest_lines" "$linesdir/lines_$(date '+%Y%m%d_%H%M%S').json"
    grep -o '"liguid":"\([^"]*\)","lname":"\([^"]*\)","ldirection":"\([^"]*\)"' "$latest_lines" > "$guid_file"
    sed -i 's/"liguid":"\([^"]*\)","lname":"\([^"]*\)","ldirection":"\([^"]*\)"/\1\t\2\t\3/' "$guid_file"
    "$dir/translate_unicode.py" "$guid_file"
    mv "$latest_lines" "$current_lines"
    echo $(date '+[%Y-%m-%d %H:%M:%S]') Lines updated, $(wc -l < "$guid_file") lines in total. >> $log_file
  fi
else
  echo $(date '+[%Y-%m-%d %H:%M:%S]') Failed to fetch lines. >> $log_file
fi

if wget -q -O "$latest_details" "http://www.wjgjw.net/busSearch/data.php"; then
  "$dir/translate_unicode.py" "$latest_details"
  if ! diff "$current_details" "$latest_details" > /dev/null; then
    cp "$latest_details" "$linesdir/details_$(date '+%Y%m%d_%H%M%S').json"
    mv "$latest_details" "$current_details"
    grep -o '{"sname":"\([^"]*\)","sguid":"\([^"]*\)",[^}]*"sroad":"\([^"]*\)","sdirect":"\([^"]*\)"[^}]*}' "$current_details" |
        sed 's/{"sname":"\([^"]*\)","sguid":"\([^"]*\)",[^}]*"sroad":"\([^"]*\)","sdirect":"\([^"]*\)"[^}]*}/\2\t\1\t\3\t\4/' |
        sort -k 2 -u > "$stops_file"
    echo $(date '+[%Y-%m-%d %H:%M:%S]') Stops updated, $(cat "$stops_file" |  wc -l) stops in total. >> $log_file

    regex='"liguid"\s*:\s*"\([^"]*\)"[^{}]*"lfstdftime"\s*:\s*"\([^"]*\)"[^{}]*"lfstdetime"\s*:\s*"\([^"]*\)"'
    grep -o "$regex" "$current_details" |
        sed 's/'"$regex"'/\1\t\2\t\3/' > "$runtimes_file"
  fi
else
  echo $(date '+[%Y-%m-%d %H:%M:%S]') Failed to fetch lines. >> $log_file
fi
