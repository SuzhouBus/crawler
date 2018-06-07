#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import datetime, json, os.path, signal

DIR = os.path.dirname(__file__)
JS_DATA_HEADER = 'var __BUS_LINE_DATA='
INCREMENTAL_STATE_FILE='_last_known_state%s.json'
PROCESSED_DATA_FILE='_last_processed_data%s.json'
DATE_RANGE_KEY = '___/*DATE_RANGE___'

_Verbose = 0
_CtrlC = 0

def _CtrlCHandler(signal, frame):
  global _CtrlC
  _CtrlC += 1

signal.signal(signal.SIGINT, _CtrlCHandler)

def _CompareDate(date1, date2):
  date1 = tuple(int(x) for x in date1.split('-'))
  date2 = tuple(int(x) for x in date2.split('-'))

  if date1 < date2:
    return -1
  if date1 > date2:
    return 1
  return 0

def _GetPreviousDate(date):
  if _GetPreviousDate.cache.get(date) is None:
    _GetPreviousDate.cache[date] = (datetime.date(*map(int, date.split('-'))) - datetime.timedelta(1)).isoformat()

  return _GetPreviousDate.cache[date]

_GetPreviousDate.cache = {}

def _LoadIncrementalState(namespace):
  path_state = os.path.join(DIR, INCREMENTAL_STATE_FILE % namespace)
  path_data = os.path.join(DIR, PROCESSED_DATA_FILE % namespace)
  if os.path.isfile(path_state) and os.path.isfile(path_data):
    with open(path_state, 'r') as state_file:
      with open(path_data, 'r') as data_file:
        return (json.load(state_file), json.load(data_file))

  if _Verbose:
    sys.stderr.write('Incremental state file does not exist. Doing a full parse...\n')
  return ({}, {})

def _SaveIncrementalState(namespace, state, data):
  try:
    with open(os.path.join(DIR, INCREMENTAL_STATE_FILE % namespace), 'w') as state_file:
      with open(os.path.join(DIR, PROCESSED_DATA_FILE % namespace), 'w') as data_file:
        json.dump(state, state_file, separators=(',', ':'), sort_keys=True)
        json.dump(data, data_file, separators=(',', ':'), sort_keys=True)
  except:
    if _Verbose:
      sys.stderr.write('Error saving incremental state file.\n')

def _FormatWeightValue(times, total):
  if times == 0:
    return '0'
  rounded_value = round(float(times) / total, 3)
  if int(rounded_value) == rounded_value:
    return str(int(rounded_value))
  return str(rounded_value)

if __name__ == '__main__':
  if len(sys.argv) <= 1:
    print 'Usage: sz_buses_parser.py [-v|--verbose] [-i|--incremental] <line...>'
    sys.exit()

  buses_map = {}
  with open('buses', 'r') as f:
    for l in f.readlines():
      values = l.split()
      if len(values) >= 2:
        buses_map[values[1]] = values[0]

  lines = []
  incremental = False
  date_range = None
  pure_json = False
  namespace = ''
  for line in sys.argv[1:]:
    if line.startswith('-'):
      if line == '-v' or line == '--verbose' or line == '-V1':
        _Verbose = 1
        continue
      if line == '-V' or line == '-V2':
        _Verbose = 2
        continue
      if line == '-V3':
        _Verbose = 3
        continue
      if line == '-i' or line == '--incremental':
        incremental = True
        continue
      if line == '--json':
        pure_json = True
        continue
      arg_range = '--range='
      if line.startswith(arg_range):
        date_range = line[len(arg_range):].split(',')
        if len(date_range) == 2:
          if len(date_range[1]) == 0:
            date_range[1] = '9999-99-99'
          date_range = (date_range[0], date_range[1])
        continue
      arg_namespace = '--namespace='
      if line.startswith(arg_namespace):
        namespace = '_%s' % line[len(arg_namespace):]
        continue

    linefile = line
    if not os.path.isfile(linefile) and os.path.isfile('%s.csv' % linefile):
      linefile = '%s.csv' % line
    if line.endswith('.csv'):
      line = line[:-4]

    lines.append((line, linefile))

  incremental_state = {}
  processed_data = {}
  if incremental:
    incremental_state, processed_data = _LoadIncrementalState(namespace)
  if date_range is not None:
    if incremental_state.get(DATE_RANGE_KEY) is None or incremental_state[DATE_RANGE_KEY] != list(date_range):
      if _Verbose:
        sys.stderr.write('Incremental state is overwritten because of date range mismatch.\n')
      incremental_state = {DATE_RANGE_KEY: list(date_range)}
      processed_data = {}
  if pure_json:
    sys.stdout.write('{')
    line_break = '\n'
  else:
    sys.stdout.write(JS_DATA_HEADER)
    sys.stdout.write('JSON.parse(\'{')
    line_break = '\\\n'

  first = True

  for line, linefile in lines:
    current_date = None
    previous_date = None
    last_fp = 0
    previous_date_ending_fp = 0
    fp_frozen = False
    processed_lines = set()
    night_line = ( line[0:1].upper() == 'N')
    running_buses = dict()
    running_buses_set = set()

    if _Verbose >= 3:
      sys.stderr.write('Parsing %s...\n' % linefile)

    with open(linefile, 'r') as f:
      file_size = os.path.getsize(linefile)
      if incremental_state.get(linefile) is not None:
        state = incremental_state[linefile]
        if file_size >= state['size']:
          if processed_data.get(line) is not None:
            running_buses = processed_data[line]['running_buses']
            running_buses_set = set(processed_data[line]['running_buses_set'])
            f.seek(state['fp'])

            if _Verbose >= 2:
              sys.stderr.write('Incrementally processing %s beginning at offset %s, after date %s\n' % (linefile, state['fp'], state['date']))
          elif _Verbose:
            sys.stderr.write('Incomplete incremental state for line %s.\n' % line)
        elif _Verbose:
          sys.stderr.write('The size of file %s has shrunk and it has to be fully parsed.\n' % linefile)

      while True:
        last_fp = f.tell()
        l = f.readline()
        if len(l) == 0:
          break
        if l in processed_lines:
          continue
        processed_lines.add(l)

        values = l.rstrip('\r\n').split(',')
        if len(values) >= 5:
          date = values[4]
          time = values[3]

          if len(date) == 0 and current_date is not None:
            date = current_date
          if current_date is None:
            current_date = date
          if len(date) > 0 and date_range is not None:
            if _CompareDate(date, date_range[0]) < 0 or _CompareDate(date, date_range[1]) > 0:
              continue
          if incremental and  current_date != date and not fp_frozen:
            if _CompareDate(date, current_date) > 0:
              if incremental_state.get(linefile) is None:
                incremental_state[linefile] = {}
              incremental_state[linefile]['size'] = file_size
              previous_date = current_date
              incremental_state[linefile]['date'] = current_date
              previous_date_ending_fp = last_fp
              incremental_state[linefile]['fp'] = last_fp
              if processed_data.get(line) is None:
                processed_data[line] = {}
              processed_data[line]['running_buses'] = running_buses
              processed_data[line]['running_buses_set'] = list(running_buses_set)
              current_date = date
            else:
              fp_frozen = True
              if _Verbose:
                sys.stderr.write('Data is not ordered chronologically for line %s: %s after %s\n' % (line, date, current_date))

          # For night lines, |date| means the date of the night when the first bus appears.
          if night_line and ':' in time and int(time.split(':')[0]) < 12:
            date = _GetPreviousDate(date)
          bus_id = values[2].replace('\\u82cf', '苏')
          prefix = '苏E-'
          if bus_id.startswith(prefix):
            bus_id = bus_id[len(prefix):]
          prefix = '苏E'
          if bus_id.startswith(prefix):
            bus_id = bus_id[len(prefix):]
          prefix = '苏'
          if bus_id.startswith(prefix):
            bus_id = bus_id[len(prefix):]
          running_buses_set.add(bus_id)
          if running_buses.get(date) is None:
            running_buses[date] = {bus_id: 1}
          else:
            if running_buses[date].get(bus_id) is None:
              running_buses[date][bus_id] =  1
            else:
              running_buses[date][bus_id] += 1
        elif _Verbose >= 3:
          sys.stderr.write('Skipped invalid entry for %s: %s' % (line, l)) # |l| has a trailing '\n'.

    if len(running_buses) > 0:
      sorted_running_buses = sorted(running_buses_set, key=lambda x:buses_map.get(x, 'Z%s' % x))

      if first:
        first = False
      else:
        sys.stdout.write(',')
      sys.stdout.write('%s"%s":{"details":[' % (line_break, line))

      sys.stdout.write((',%s' % line_break).join([
        '["%s",[%s]]' % (date,
          ','.join([_FormatWeightValue(buses.get(bus_id, 0), max(buses.values()))
            for bus_id in sorted_running_buses]))
        for date, buses in sorted(running_buses.iteritems(), key=lambda x:x[0])])
      )
      sys.stdout.write('%s],"buses":[%s]}' % (line_break, 
          ','.join(['{"busId":"%s","licenseId":"%s"}' % (buses_map.get(x, ''), x.encode('utf-8')) for x in sorted_running_buses])))

    elif _Verbose:
      sys.stderr.write('Skipped line with empty data: %s\n' % line)

    if _CtrlC:
      sys.stderr.write('\nCtrl-C pressed. Aborting...\n')
      break

  if pure_json:
    sys.stdout.write('}')
  else:
   sys.stdout.write('}\')')

  if incremental:
    _SaveIncrementalState(namespace, incremental_state, processed_data)
