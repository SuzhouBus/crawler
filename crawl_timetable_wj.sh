#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/wj"
log_file="$basedir/timetable.log"
guid_file="$basedir/all.guid"
map_file="$basedir/map.guid"
lines_file="$basedir/lines/current_details.json"
runtimes_file="$basedir/runtimes.map"
today="$(date '+%Y-%m-%d')"
timetabledir="$basedir/timetable"
timetablefile="$basedir/timetable.csv"
time="$(date '+%H:%M')"
NO_BUS_QUERY_INTERVAL=5
MINUTE_DELTA_NEW_DAY_THRESHOILD=-60
MINUTE_DETLA_LAST_RUN_THRESHOLD=$((NO_BUS_QUERY_INTERVAL * 2))

line_count=0
query_count=0
new_entry_count=0
last_run_ended_count=0
wait_for_next_run_count=0
request_failure_count=0
no_pending_bus_count=0
unfinished_last_state_count=0
start_time=`date +%s`

#false_count=$(grep -l -F false $timetabledir/* | wc -l)
#echo $false_count
### HACK
#grep -l -F false $timetabledir/* | xargs rm

convert_result()
{
  local new_result="$1"
  if grep -F false "$new_result" > /dev/null; then
    no_pending_bus_count=$((no_pending_bus_count + 1))
    echo -n "NULL,$time" > "$new_result"
  else
    sed -i 's/{.*"starttime"\s*:\s*"\([0-9][0-9]\)\([0-9][0-9]\)".*"dbuscard"\s*:\s*"\([^"]*\)"}/\3,\1:\2/' "$new_result"
  fi
}

for guid in $(grep -v '^#\|^$' "$guid_file" | cut -f1); do
  line_count=$((line_count + 1))

  new_result="$timetabledir/$guid.new"
  last_result="$timetabledir/$guid.last"

  if grep '{\|false' "$last_result" > /dev/null; then
    convert_result "$last_result"
    unfinished_last_state_count=$((unfinished_last_state_count + 1))
  fi
  last_time=$(cut -d, -f2 < "$last_result")
  last_hour=${last_time%:*}
  last_minute=${last_time#*:}
  hour=${time%:*}
  minute=${time#*:}
  minute_delta=$((10#$hour * 60 - 10#$last_hour * 60 + 10#$minute - 10#$last_minute))
  # If it's not a new day.
  if [[ $minute_delta -gt $MINUTE_DELTA_NEW_DAY_THRESHOILD ]]; then
    # If current time <= scheduled time for the next run AND it's not a new day.
    if [[ ! "$time" > "$last_time" ]]; then
      wait_for_next_run_count=$((wait_for_next_run_count + 1))
      continue
    fi

    last_bus=$(cut -d, -f1 < "$last_result")
    # No pending bus run in the last query.
    if [[ "$last_bus" == "NULL" ]]; then
      # If it has been well beyond service time.
      if [[ $minute_delta -lt $NO_BUS_QUERY_INTERVAL ]]; then
        continue
      fi
      last_run_time=$(grep "$guid" "$runtimes_file" | head -n 1 | cut -f3 | sed 's/\(..\)\(..\)/\1:\2/')
      if [[ "$last_run_time" == "" ]]; then
        last_run_time=99:99
      fi
      last_run_hour=${last_run_time%:*}
      last_run_minute=${last_run_time#*:}
      last_run_minute_delta=$((10#$hour * 60 - 10#$last_run_hour * 60 + 10#$minute - 10#$last_run_minute))
      # Wait for MINUTE_DETLA_LAST_RUN_THRESHOLD before another query.
      if [[ $last_run_minute_delta -ge $MINUTE_DETLA_LAST_RUN_THRESHOLD ]]; then
        last_run_ended_count=$((last_run_ended_count + 1))
        continue
      fi
    fi
  fi

  query_count=$((query_count + 1))
  if ! wget -q -O "$new_result" "http://www.wjgjw.net/busSearch/getStart.php?guid=$guid"; then
    request_failure_count=$((request_failure_count + 1))
    continue
  fi
  convert_result "$new_result"
  if ! diff -q "$new_result" "$last_result" > /dev/null; then
    new_entry_count=$((new_entry_count + 1))
    sed 's/.*/'"$today"',&,'"$guid"'\n/' "$new_result" >> "$timetablefile"
    mv "$new_result" "$last_result"
  #elif ! grep 'false' "$new_result" > /dev/null; then
  #  echo DEBUG: $guid $last_time $last_bus $minute_delta $(cat $new_result) $time >> $log_file
  fi
done

end_time=`date +%s`
echo `date '+[%Y-%m-%d %H:%M:%S]'` Processed $line_count lines with $request_failure_count errors out of $query_count requests, getting $new_entry_count new runs in $((end_time - start_time)) seconds. $last_run_ended_count lines have been out of service, $no_pending_bus_count lines have no pending bus and $wait_for_next_run_count lines pending. "/$unfinished_last_state_count/" >> $log_file
