#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re, sys

if __name__ == '__main__':
  regex = re.compile(r'\\u[0-9a-fA-F]{4}')
  def replace(match):
    return unichr(int(match.group(0)[2:], 16)).encode('utf-8')

  if len(sys.argv) > 1:
    for cur in sys.argv[1:]:
      with open(cur, 'r+') as f:
        result = regex.sub(replace, f.read())
        f.seek(0)
        f.truncate()
        f.write(result)
  else:
    for line in sys.stdin:
      sys.stdout.write(regex.sub(replace, line))
