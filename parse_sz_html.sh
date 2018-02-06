#!/bin/bash

cat $* | grep -a '<tr><td><a href="[^"]*">\([^<]*\)</a></td><td>\([^<]*\)</td><td>\([^<]*\)</td><td>\([^<]*\)</td></tr>' | sed 's#<tr><td><a href="[^"]*">\([^<]*\)</a></td><td>\([^<]*\)</td><td>\([^<]*\)</td><td>\([^<]*\)</td></tr>#\n\1,\2,\3,\4\n#g' | grep -v '<' | grep -v '^$'
