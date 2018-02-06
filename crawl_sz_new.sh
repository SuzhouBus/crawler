#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
baseurl='http://www.szjt.gov.cn/Manager.aspx?PageGuid=bf6cf9f4-4e23-4bac-9ecd-062b859a820d'
lineguid="$1"

if [[ "$lineguid" == "" ]]; then
  lineguid="b9434375-db2d-49c0-9561-938fa7b29071"
fi

# grep '</\?option' 1.txt | paste -sd' ' | grep -o '<option[^>]*>[^<]*</option>'|sed 's!<option.*\?value="\([^"]*\)">\([^<]*\)</option>!\1\t\2!' > 1.guid
# grep -F '|error|'

wget2()
{
  wget -q -O /dev/stdout --header="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.108 Safari/537.36" "$@"
}

make_post_file()
{
  (
    # DO NOT change the order of the following arguments.
    echo 'ctl00%24ContentPlace%24ScriptManager1=ctl00%24ContentPlace%24ctl00%24UpdatePanel1%7Cctl00%24ContentPlace%24ctl00%24ManualRefresh'
#    wget2 "$baseurl" |
    cat "$1.state" |
      grep -F 'input type="hidden"' |
      sed 's/+/%2B/g'|
      sed 's!/!%2F!g'|
      sed 's/=/%3D/g' |
      sed 's!\s*<input type%3D"hidden" name%3D"\([^"]*\)" id%3D"[^"]*" value%3D"\([^"]*\)".*!\1=\2!'
    echo 'ctl00%24ContentPlace%24HiddenUserID='
    echo "ctl00%24ContentPlace%24ctl00%24LineList=$lineguid"
    echo '__ASYNCPOST=true'
    echo 'ctl00%24ContentPlace%24ctl00%24ManualRefresh=%E5%88%B7%E6%96%B0'
  ) | paste -d'&' -s
}

if grep -F "$lineguid" 1.guid; then
  tempdir=$(mktemp -d "${TMPDIR:-/tmp/}$(basename $0).XXXXXXXXXXXX")
  postfile="$tempdir/post"
  make_post_file 1 > $postfile

  wget2 --post-file="$postfile" --header="Content-Type: application/x-www-form-urlencoded; charset=UTF-8" --header="Referer: $baseurl" --header="X-MicrosoftAjax: Delta=true" --header="X-Requested-With: XMLHttpRequest" "$baseurl"
  rm -rf "$tempdir"
else
  echo "Cannot find guid $lineguid!"
fi
