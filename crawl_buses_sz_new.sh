#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
basedir="$dir/data/sz/buses"
guid_file="$basedir/guids"
log_file="$basedir/logs"

line_count=0
url_manager_count=0
url_normal_count=0
no_data_count=0
bus_count=0

if [ "$1" != "" ]; then
  guid_file="$basedir/$1"
fi

current_time=$(date '+%H:%M')

parse_and_format_base()
{
  if [[ "$1" == 1 ]]; then
    "$dir/parse_sz_html.sh"
  else
    "$dir/parse_sz_html2.sh"
  fi | grep -v ',,$' | sed s/\$/,$(date +%Y-%m-%d),$2/
}

parse_and_format()
{
  local result=$("$dir/crawl_sz_new.sh" $1 | parse_and_format_base)
  if [[ "$result" == "" ]] && [[ "$1" != "56211045-bc3b-4138-89a0-b4e0ced0811e" ]] && [[ "$1" != "f3c3fd86-ccf1-47f9-9bc0-5624479199ee" ]]; then
#    echo "Line $1 is requested with fallback url." >> "$log_file"
    result=$("$dir/crawl_sz_new.sh" $1 --fallback-url | parse_and_format_base 1)
    url_normal_count=$((url_normal_count + 1))
    if [[ "$result" == "" ]]; then
      no_data_count=$((no_data_count + 1))
    fi
  else
    url_manager_count=$((url_manager_count + 1))
  fi
  if [[ "$result" != "" ]]; then
    echo "$result"
  fi
  bus_count=$((bus_count + $(echo "$result" | wc -l)))
}

# Usage:
# crawl_line <line> <guid1> <guid2> <time11> <time12> <time21> <time22>
#              $1      $2      $3      $4       $5       $6      $7
crawl_line()
{
  line_count=$((line_count + 1))
  echo $1
  if [[ ! "$current_time" < "$4" ]] && [[ ! "$current_time" > "$5" ]]; then
    parse_and_format $2 0 >> "$basedir/${1}.csv"
    sleep 0.5
  fi
  if [[ ! "$current_time" < "$6" ]] && [[ ! "$current_time" > "$7" ]]; then
    parse_and_format $3 1 >> "$basedir/${1}.csv"
    sleep 0.5
  fi
}

# Usage:
# crawl_line1 <line> <guid1> <time11> <time12>
#              $1       $2      $3       $4
crawl_line1()
{
  line_count=$((line_count + 1))
  echo $1
  if [[ ! "$current_time" < "$3" ]] && [[ ! "$current_time" > "$4" ]]; then
    parse_and_format $2 0 >> "$basedir/${1}.csv"
    sleep 0.5
  fi
}

start_time=$(date +%s.%N)

crawl_line 2SND 11681df8-f0ff-4927-92c1-ad6d0bd8db98 aa088e40-67f6-4b8d-8f35-abcc5f6de323 05:20 23:59 05:30 23:59
crawl_line 9 adc97abd-b23e-428e-ad75-31cd99ba1ff5 628fda0e-b239-4c44-b2b3-b95f99341109 05:00 23:10 05:15 23:50
crawl_line 931 cc503086-afd5-4386-b8f5-d17aeea4f5bd 57b0ff12-962b-45ae-9fe9-31458620e26b 05:00 23:00 05:15 23:30
crawl_line1 10E fbe2afe7-aa3a-465b-947a-312bc24cdbe9 05:00 23:59
crawl_line1 10W 59b4646c-2073-4fb9-9093-cb0daf02e4a0 05:00 23:59
crawl_line 301 3d67a744-e607-4061-ae1f-8611ca7f61a2 aede6e29-57fb-4ede-a2d4-e4ecae1b42dc 05:00 23:20 05:50 23:59
crawl_line 513 3176d075-6114-4946-85e8-1c872f21fc0d 7a417b27-7730-4504-b159-a8cfe86c6729 05:00 19:20 06:00 20:20
crawl_line1 9013W a2b78df0-58ec-4f19-85be-1f7225ca8f76 06:30 21:20
crawl_line1 9013E 596bc27c-2017-46ba-8574-3520e4d701b5 06:30 21:20
crawl_line 923 7e268e90-1f2e-4bc9-9f65-9c13e11242ec 6d2132ca-6870-4598-bd5a-656ef03c5880 05:15 21:50 06:20 22:55
crawl_line 45 e3fd5980-02f1-46be-942e-1ad8e10d67c8 0a9b8652-f14b-4067-b8cf-042096c68f84 06:00 21:55 06:00 22:50
crawl_line 933 a2aea4d3-7be2-41e3-af2c-8fa523cc0b2d cc7ae058-37b4-4aa3-953c-718fecdd8b67 06:00 22:20 06:00 22:20
crawl_line 937 e1e1114d-249c-4ead-89df-2c4b256e9200 79341e59-b6ef-4004-9edd-a80b9d208312 06:30 21:00 06:30 21:50
#crawl_line 36 bc22894b-8731-4bb5-8484-8c2e122e48f9 decad920-9da3-4a83-ae33-656ce47968ac 05:45 21:00 06:25 21:00
crawl_line 692 C3FC757E-F47C-4B70-9414-F5715BA47D08 41D1E74F-9802-44CB-9813-523B2C73B22A 06:00 21:30 06:00 21:30
#crawl_line 866 EF9DCDA2-5ACE-4D44-BC1E-581697553EB0 76DA56C6-F348-4D53-873E-20F81589EF65 06:00 20:30 06:00 21:00
#                                                                                              19:30       20:00
#crawl_line 585 776270CD-C2F3-4FE0-8E76-772388F02B6E 548C9CAB-34C5-4DC6-8781-59CC05EBDC58 06:00 20:00 06:00 20:00
#                                                                                              19:00       19:00
crawl_line 31 56211045-bc3b-4138-89a0-b4e0ced0811e f3c3fd86-ccf1-47f9-9bc0-5624479199ee 06:00 19:30 06:30 20:40
crawl_line 33 f92620e5-a1a8-4134-92c9-3f544d46f8ba 6c602a2c-ad05-4112-a87c-ebfbd1651799 06:00 19:30 07:00 20:30
crawl_line 87 D0901849-69B7-5F89-F655-411C2BAB14DC 02E7D513-08F5-72AC-6CAF-3000D65641D0 05:30 20:50 05:45 20:50
crawl_line1 K8Z 989617FB-56A8-4E9D-89A8-4D35C5071C89 06:30 10:20
crawl_line1 K8Z 989617FB-56A8-4E9D-89A8-4D35C5071C89 16:00 19:50
crawl_line K8 8C00009A-1E4B-4459-BB67-7C61FA231068 EA711D64-337E-44D5-A6E8-CECF8548B6E7 05:30 23:00 05:50 23:00
crawl_line 807 5CD5218B-A0C3-49DE-AE41-E4B15B26FE35 7AAE0164-888B-4B2F-83D9-3DFC081EAB7D 06:20 19:45 06:45 20:10

end_time=$(date +%s.%N)
echo '['$(date '+%Y-%m-%d %H:%M:%S')']' Crawled $bus_count buses out of $line_count lines '('Manager.aspx: $url_manager_count/APTSLine.aspx: $url_normal_count/No data: $no_data_count')' in $(bc -l <<< "scale=2;$end_time-$start_time") seconds, $(bc -l <<< "scale=2;($end_time-$start_time)/$line_count") seconds in average for each line. >> "$log_file"

if [[ "${current_time:0:2}" == "23" || "${current_time:0:2}" == "00" ]] && [[ "${current_time:3}" < "05" || "${current_time:3}" == "59" ]]; then
  cp -rf "$dir/." /cygdrive/c/Users/dmtab/OneDrive/bus/
fi


#crawl_line 557 B26ABB1C-7FF9-47DA-84AA-6985A6689805 DE0F2DFE-63BA-486C-9B56-C18893ED5A88 05:50 20:00 05:50 20:00
#                                                                                              19:00       19:00
#crawl_line 558 b77ec824-d014-454a-a66e-d0a6a47bd11f 55132b0f-caa4-4e56-aca0-a61bc390d5ee 06:00 20:00 06:00 20:00
#                                                                                              19:00       19:00
# crawl_line 331 72b93460-523f-4353-8a3f-616f55e9962e a008dd4b-e841-4f75-bc82-d7907f5b6d47 07:00 19:00 07:30 19:40
# crawl_line 9013 a2b78df0-58ec-4f19-85be-1f7225ca8f76 07:00 19:40
# crawl_line1 9026 89c43701-c29a-445c-ae9d-c5998334283d 06:15 20:30