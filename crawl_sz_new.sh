#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmpdir="$dir/tmp"
statesdir="$dir/states"
statesdir_active="$statesdir/active"
baseurl='http://www.szjt.gov.cn/Manager.aspx?PageGuid=bf6cf9f4-4e23-4bac-9ecd-062b859a820d'
baseurl_fallback='www.szjt.gov.cn/BusQuery/APTSLine.aspx?LineGuid='
lineguid="$1"
logfile="$dir/data/sz/buses/logs"
use_fallback_url=0

if [[ "$2" == "--fallback-url" ]]; then
  use_fallback_url=1
fi

if ! [ -d "$tmpdir" ]; then
  mkdir "$tmpdir"
fi

if [[ "$lineguid" == "" ]]; then
  lineguid="b9434375-db2d-49c0-9561-938fa7b29071"
fi

wget2()
{
  #wget -q -O /dev/stdout --header="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537.36" "$@"
  wget -q -O /dev/stdout --header="User-Agent: Mozilla" "$@"
}

# make_post_file <state file> <line guid>
make_post_file()
{
  (
    # DO NOT change the order of the following arguments.
    echo 'ctl00%24ContentPlace%24ScriptManager1=ctl00%24ContentPlace%24ctl00%24UpdatePanel1%7Cctl00%24ContentPlace%24ctl00%24ManualRefresh'
    cat "$1" |
      grep -F 'input type="hidden"' |
      sed 's/+/%2B/g'|
      sed 's!/!%2F!g'|
      sed 's/=/%3D/g' |
      sed 's!\s*<input type%3D"hidden" name%3D"\([^"]*\)" id%3D"[^"]*" value%3D"\([^"]*\)".*!\1=\2!'
    echo 'ctl00%24ContentPlace%24HiddenUserID='
    echo "ctl00%24ContentPlace%24ctl00%24LineList=$2"
    echo '__ASYNCPOST=true'
    echo 'ctl00%24ContentPlace%24ctl00%24ManualRefresh=%E5%88%B7%E6%96%B0'
  ) | paste -d'&' -s
}

find_state()
{
  RETURN_VALUE=
  local statesdir=$1
  local lineguid=$2
  for x in $(ls -Sr1 $statesdir/*.state); do
    local statename="${x/\.state/}"
    local guidfile="$statename.guid"
    if ! [ -f "$guidfile" ]; then
      local tmpguidfile="$(mktemp -p "$tmpdir" "XXXXXXXX.guid")"
      grep '</\?option' "$x" | paste -sd' ' | grep -o '<option[^>]*>[^<]*</option>'|sed 's!<option.*\?value="\([^"]*\)">\([^<]*\)</option>!\1\t\2!' > "$tmpguidfile"
      mv "$tmpguidfile" "$guidfile"
    fi
    if grep -F "$lineguid" "$guidfile"; then
      RETURN_VALUE=$statename
      break
    fi
  done
}

if [[ "$use_fallback_url" == 1 ]]; then
  wget2 "$baseurl_fallback$lineguid"
else
  find_state "$statesdir_active" "$lineguid"
  if [[ "$RETURN_VALUE" == "" ]]; then
    find_state "$statesdir" "$lineguid"
    if [[ "$RETURN_VALUE" == "" ]]; then
      echo "ERROR: Cannot find guid $lineguid!"
      exit 1
    else
      mv "$RETURN_VALUE.state" "$statesdir_active"
      mv "$RETURN_VALUE.guid" "$statesdir_active"
      RETURN_VALUE="$statesdir_active/$(basename "$RETURN_VALUE")"
    fi
  fi
  echo $RETURN_VALUE
  statename="$RETURN_VALUE"
  #  echo $statename $(wc -c < "$statename.state")
  postfile="$(mktemp -p "$tmpdir" "XXXXXXXX.post")"
  make_post_file "$statename.state" "$lineguid" > "$postfile"
###  echo '[STATE]' $(grep $lineguid $statename.guid) $statename.state $(wc -c < $statename.state) $(wc -c $postfile) >> $logfile
  wget2 --post-file="$postfile" --header="Content-Type: application/x-www-form-urlencoded; charset=UTF-8" --header="Referer: $baseurl" --header="X-MicrosoftAjax: Delta=true" --header="X-Requested-With: XMLHttpRequest" "$baseurl"
  rm "$postfile"
fi


# grep -F '|error|'
