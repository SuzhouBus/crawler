#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/sz/buses"
guid_file="$basedir/guids"
log_file="$basedir/logs"

if [ "$1" != "" ]; then
  guid_file="$basedir/$1"
fi

current_time=$(date '+%H:%M')

parse_and_format()
{
  pushd "$dir" > /dev/null
  ./crawl_sz_new.sh $1 | ./parse_sz_html2.sh | grep -v ',,$' | sed s/\$/,$(date +%Y-%m-%d),$2/
  popd > /dev/null
}

# Usage:
# crawl_line <line> <guid1> <guid2> <time11> <time12> <time21> <time22>
#              $1      $2      $3      $4       $5       $6      $7
crawl_line()
{
  if [[ ! "$current_time" < "$4" ]] && [[ ! "$current_time" > "$5" ]]; then
    parse_and_format $2 0 >> "$basedir/${1}.csv"
    sleep 0.5
  fi
  if [[ ! "$current_time" < "$6" ]] && [[ ! "$current_time" > "$7" ]]; then
    echo "$basedir/$line.csv"
    parse_and_format $3 1 >> "$basedir/${1}.csv"
    sleep 0.5
  fi
}

# parse_and_format B26ABB1C-7FF9-47DA-84AA-6985A6689805 0 >> "$basedir/557.csv"
# parse_and_format DE0F2DFE-63BA-486C-9B56-C18893ED5A88 1 >> "$basedir/557.csv"

crawl_line 557 B26ABB1C-7FF9-47DA-84AA-6985A6689805 DE0F2DFE-63BA-486C-9B56-C18893ED5A88 05:50 20:00 05:50 20:00
#                                                                                              19:00       19:00
crawl_line 558 b77ec824-d014-454a-a66e-d0a6a47bd11f 55132b0f-caa4-4e56-aca0-a61bc390d5ee 06:00 20:00 06:00 20:00
#                                                                                              19:00       19:00
crawl_line 585 776270CD-C2F3-4FE0-8E76-772388F02B6E 548C9CAB-34C5-4DC6-8781-59CC05EBDC58 06:00 20:00 06:00 20:00
#                                                                                              19:00       19:00
crawl_line 866 EF9DCDA2-5ACE-4D44-BC1E-581697553EB0 76DA56C6-F348-4D53-873E-20F81589EF65 06:00 20:30 06:00 21:00
#                                                                                              19:30       20:00

