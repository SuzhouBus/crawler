#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/sz/buses"
guid_file="$basedir/guids"
log_file="$basedir/logs"

if [ "$1" != "" ]; then
  guid_file="$basedir/$1"
fi

line_count=0
bus_count=0
start_time=`date +%s`

grep -v '^#\|^$' "$guid_file" | (
  while read entry; do
    line=`echo "$entry" | cut -d ' ' -f 1`
    buses_file="$basedir/$line.buses"
    csv_file="$basedir/$line.csv"
    echo $line

    line_count=$((line_count + 1))
    direction_id=0
    for guid in `echo "$entry" | cut -d ' ' -f 2-`; do
      echo $guid
      results=$(wget -q -O /dev/stdout "http://www.szjt.gov.cn/BusQuery/APTSLine.aspx?LineGuid=$guid" | "$dir/parse_sz_html.sh")
      echo "$results" | grep -v ',,$' | sed s/\$/,$(date +%Y-%m-%d),"$direction_id"/ >> "$csv_file"
      buses=`echo "$results" | cut -d , -f 3 | grep -v '^$'`
      direction_id=$((direction_id + 1))
      sleep 0.9

      for bus in $buses; do
        bus_count=$((bus_count + 1))
        if ! grep -F "$bus" "$buses_file" > /dev/null; then
          echo "$bus" >> "$buses_file"
          echo New bus of "$line": "$bus"
          echo `date '+[%Y-%m-%d %H:%M:%S]'` New bus of "$line": "$bus" >> $log_file
        fi
      done
    done

  done

  end_time=`date +%s`

  echo `date '+[%Y-%m-%d %H:%M:%S]'` Processed $bus_count buses of $line_count lines from $guid_file in $((end_time - start_time)) seconds. >> $log_file
)
