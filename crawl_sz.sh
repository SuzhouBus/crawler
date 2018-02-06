#!/bin/bash

# Usage: crawl.sh <line> <lineGUID> <description>

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
baseurl="http://www.szjt.gov.cn/apts/APTSLine.aspx?LineGuid="

lineID=$1
lineGUID=$2
lineDescription=$3
today=`date '+%Y%m%d'`
time=`date '+%H%M'`
datapath="$dir/data/sz/$lineID/$today"

if [ ! -d "$datapath" ]; then
  mkdir $datapath
fi

wget -q -O "$datapath/${time}_$lineDescription.htm" "$baseurl$lineGUID"
