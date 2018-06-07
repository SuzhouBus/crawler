#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/wj"
log_file="$basedir/logs"
guid_file="$basedir/all.guid"
extra_guid_file="$basedir/extra.guid"
map_file="$basedir/map.guid"
today="$(date '+%Y%m%d')"

line_count=0
bus_count=0
start_time=`date +%s`

grep -h -v '^#\|^$' "$extra_guid_file" "$guid_file" | (
  while read entry; do
    guid=$(echo "$entry" | cut -f 1)
    line=$(echo "$entry" | cut -f 2)
    direction=$(echo "$entry" | cut -f 3)
    if grep -F "$guid" "$map_file" > /dev/null; then
      line=$(grep -F "$guid" "$map_file" | head -n 1 | cut -f 4)
    elif grep -F $'\t'"$line"$'\t' "$map_file" > /dev/null; then
      line=$(grep -F "$line" "$map_file" | head -n 1 | cut -f 4)
    fi
    buses_file="$basedir/$line.buses"
    csv_file="$basedir/$line.csv"
    echo $line

    line_count=$((line_count + 1))
    results=$(wget -q -O /dev/stdout "http://www.wjgjw.net/busSearch/getInstant.php?guid=$guid" |
      grep -o '"dbuscard":"\([^"]*\)",[^}]*"sguid":"\([^"]*\)",[^}]*"lastlongitude":"\([^"]*\)","lastlatitude":"\([^"]*\)","lastspeed":\([0-9]*\),[^}]*"modifydate":"\([^"]*\)"' |
#                              \1                     \2                            \3                         \4                      \5                       \6
      sed 's/"dbuscard":"\([^"]*\)",[^}]*"sguid":"\([^"]*\)",[^}]*"lastlongitude":"\([^"]*\)","lastlatitude":"\([^"]*\)","lastspeed":\([0-9]*\),[^}]*"modifydate":"\([^"]*\)"/,\2,\1,\6,'"$(date +%Y-%m-%d)","$direction",'\3,\4,\5/'
    )
    echo "$results" >> "$csv_file"
    buses=$(echo "$results" | cut -d , -f 3 | grep -v '^$')
    sleep 0.3

    for bus in $buses; do
      bus_count=$((bus_count + 1))
      if ! grep -F "$bus" "$buses_file" > /dev/null; then
        echo "$bus" >> "$buses_file"
        echo New bus of "$line": "$bus"
        echo `date '+[%Y-%m-%d %H:%M:%S]'` New bus of "$line": "$bus" >> $log_file
      fi
    done

  done

  end_time=`date +%s`

  echo `date '+[%Y-%m-%d %H:%M:%S]'` Processed $bus_count buses of $line_count lines from $guid_file in $((end_time - start_time)) seconds. >> $log_file
)
