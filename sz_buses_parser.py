#!/usr/bin/env python
# -*- coding: utf-8 -*-

import datetime, os.path, sys

COLOR = (106, 90, 205)
WHITE = (255, 255, 255)
DATA_HEADER = 'var __BUS_LINE_DATA='

def _GetPreviousDate(date):
  if _GetPreviousDate.cache.get(date) is None:
    _GetPreviousDate.cache[date] = (datetime.date(*map(int, date.split('-'))) - datetime.timedelta(1)).isoformat()

  return _GetPreviousDate.cache[date]

_GetPreviousDate.cache = {}

if __name__ == '__main__':
  if len(sys.argv) <= 1:
    print 'Usage: sz_buses_parser.py <line...>'
    sys.exit()

  verbose = False

  buses_map = {}
  with open('buses', 'r') as f:
    for l in f.readlines():
      values = l.split()
      if len(values) >= 2:
        buses_map[values[1]] = values[0]

#  print '''<!doctype html>
  '''<html>
  <head>
    <meta charset="utf-8">
    <title>Buses</title>
    <style>
      col.bus_id {
        background-color: LightGoldenRodYellow;
      }
      col.direction_0 {
        background-color: PaleTurquoise;
      }
      col.direction_1 {
        background-color: Plum;
      }

      #contents {
        column-count: 4;
        column-rule: 1px solid grey;
        column-gap: 5em;
      }

      td.active {
        background-color: SkyBlue;
      }

      th, td:nth-child(1) {
        white-space: nowrap;
      }
    </style>'''

  lines = []
  for line in sys.argv[1:]:
    if line == '-v' or line == '--verbose':
      verbose = True
      continue

    linefile = line
    if not os.path.isfile(linefile) and os.path.isfile('%s.csv' % linefile):
      linefile = '%s.csv' % line
    if line.endswith('.csv'):
      line = line[:-4]

    lines.append((line, linefile))

#  print '<script type="application/json" id="lineData">{'
  sys.stdout.write(DATA_HEADER)
  sys.stdout.write('JSON.parse(\'{')
  first = True
  for line, linefile in lines:
    if first:
      first = False
    else:
      sys.stdout.write(',')
    sys.stdout.write('\\\n"%s":{"details":[' % line)

    night_line = ( line[0:1].upper() == 'N')
    running_buses = dict()
    running_buses_set = set()
    with open(linefile, 'r') as f:
      for l in set(f.readlines()):
        values = l.rstrip('\r\n').split(',')
        if len(values) >= 5:
          date = values[4]
          time = values[3]
          # For night lines, |date| means the date of the night when the first bus appears.
          if night_line and ':' in time and int(time.split(':')[0]) < 12:
            date = _GetPreviousDate(date)
          bus_id = values[2]
          prefix = '苏E-'
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
        elif verbose:
          sys.stderr.write('Skipped invalid entry for %s: %s\n' % (line, l))

    sorted_running_buses = sorted(running_buses_set, key=lambda x:buses_map.get(x, 'Z%s' % x))

    sys.stdout.write(',\\\n'.join([
      '["%s",[%s]]' % (date,
        ','.join([str(round(float(buses.get(bus_id, 0)) / max(buses.values()), 3))
          for bus_id in sorted_running_buses]))
      for date, buses in sorted(running_buses.iteritems(), key=lambda x:x[0])])
    )
    sys.stdout.write('\\\n],"buses":[%s]}' % ','.join(['{"busId":"%s","licenseId":"%s"}' % (buses_map.get(x, ''), x) for x in sorted_running_buses]))
  print '}\')'
#  print '''}</script>
  '''    <script>
      var COLOR = [106, 90, 205];
      var PALETTE = [
        [106, 90, 205],
        [34, 139, 34],
        [178, 34, 34],
        [218, 165, 32],
        [128, 0, 128],
      ];

      var lineData = {};
      var activeLines = [];

      function fillTr(data, th, attrs) {
        var tr = document.createElement('tr');
        [].forEach.call(data, function(item, index) {
          var td = document.createElement(th ? 'th' : 'td');
          if (attrs && attrs[index])
          for (var x in attrs[index])
            td.setAttribute(x, attrs[index][x]);
          td.appendChild(document.createTextNode(item));
          tr.appendChild(td);
        });
        return tr;
      }

      function removeChildren(parent) {
        while(parent.hasChildNodes())
          parent.removeChild(parent.childNodes[0]);
      }

      function showLine(line) {
        activeLines = [line];
        var content = document.getElementById('content');
        removeChildren(content);
        if (!lineData[line]) {
          content.appendChild(document.createTextNode('Line ' + line + ' does not exist!'));
          return;
        }

        var table = document.createElement('table');
        var tbody = document.createElement('tbody');
        tbody.appendChild(fillTr(["Bus ID"].concat(lineData[line].buses.map(bus => bus.busId)), true));
        tbody.appendChild(fillTr(["License ID"].concat(lineData[line].buses.map(bus => bus.licenseId)), true));
        lineData[line].details.forEach(function(day) {
          tbody.appendChild(fillTr([day[0]].concat(new Array(day[1].length).fill('')), false, [''].concat(day[1].map(function(weight){
            return {style: 'background-color:rgb(' + COLOR.map(function(value) {
              return parseInt((255 - value) * (1 - weight) + value);
            }).join(',') + ')'};
          }))));
        });
        table.appendChild(tbody);
        content.appendChild(table);
      }

      function findBusById(query, busId) {
        var resultList = document.getElementById('resultList');
        removeChildren(resultList);
        for (var line in lineData) {
          if (lineData[line].buses.some(function(bus) {
            if (busId)
              return bus.busId[0] == query[0] && bus.busId.substr(2) == query.substr(2);
            else
              return bus.licenseId == query;
          })) {
            var option = document.createElement('option');
            option.value = line;
            option.appendChild(document.createTextNode(line));
            resultList.appendChild(option);
          }
        }
      }

      function showLines(lines) {
        var content = document.getElementById('content');
        var legend = document.getElementById('legend');
        removeChildren(content);
        removeChildren(legend);

        if (lines.length > PALETTE.length) {
          content.appendChild(document.createTextNode('Too many lines selected!'));
          return;
        }

        if (lines.some(line => !lineData[line])) {
          content.appendChild(document.createTextNode('Not all lines exist!'));
          return;
        }

        for (var i = 0; i < lines.length; ++i) {
          var item = document.createElement('span');
          var span = document.createElement('span');
          span.style.backgroundColor = 'rgb(' + PALETTE[i].join(',') + ')';
          span.style.height = '1em';
          span.style.width = '2em';
          span.style.display = 'inline-block';
          item.style.marginLeft = '3em';
          item.appendChild(span);
          item.appendChild(document.createTextNode(' ' + lines[i]));
          legend.appendChild(item);
        }

        var allBuses = [];
        var licenseIdSet = new Set();
        var lineDetailsMap = {};
        for (var i = 0; i < lines.length; ++i) {
          currentLineData = lineData[lines[i]];

          currentLineData.buses.forEach(function(bus) {
            if (!licenseIdSet.has(bus.licenseId)) {
              allBuses.push(bus);
              licenseIdSet.add(bus.licenseId);
            }
          });
          currentLineData.details.forEach(function(day) {
            if (!lineDetailsMap[day[0]]) {
              lineDetailsMap[day[0]] = {};
            }
            for (var j = 0; j < currentLineData.buses.length; ++j) {
              var licenseId = currentLineData.buses[j].licenseId;
              if (!lineDetailsMap[day[0]][licenseId])
                lineDetailsMap[day[0]][licenseId] = new Array(lines.length).fill(0);
              lineDetailsMap[day[0]][licenseId][i] = day[1][j];
            }
          });
        }

        allBuses.sort(function(a, b) {
          if (a.busId && b.busId) {
            if (a.busId < b.busId)
              return -1;
            else if (a.busId > b.busId)
              return 1;
            else
              return 0;
          } else if (a.busId && !b.busId) // a < b
            return -1;
          else if (!a.busId && b.busId) // a > b
            return 1;
          else {
            if (a.licenseId < b.licenseId)
              return -1;
            else if (a.licenseId > b.licenseId)
              return 1;
            return 0;
          }
        });

        var table = document.createElement('table');
        var tbody = document.createElement('tbody');
        tbody.appendChild(fillTr(["Bus ID"].concat(allBuses.map(bus => bus.busId)), true));
        tbody.appendChild(fillTr(["License ID"].concat(allBuses.map(bus => bus.licenseId)), true));
        Object.keys(lineDetailsMap).sort().forEach(function(date) {
          var tr = document.createElement('tr');
          var th = document.createElement('th');
          th.appendChild(document.createTextNode(date));
          tr.appendChild(th);
          allBuses.forEach(function(bus) {
            var td = document.createElement('td');
            tr.appendChild(td);
            var activeCount = 0;
            if (lineDetailsMap[date][bus.licenseId]) {
              activeCount = lineDetailsMap[date][bus.licenseId].filter(x => x > 0).length;
            }
            if (activeCount == 0)
              return;

            lineDetailsMap[date][bus.licenseId].forEach(function(weight, index) {
              if (weight > 0) {
                var children = document.createElement('span');
                children.style.height = '100%';
                children.style.width = 'calc(100%/' + activeCount + ')';
                children.style.display = 'inline-block';
                children.style.backgroundColor = 'rgb(' + PALETTE[index].map(function(value) {
                  return parseInt((255 - value) * (1 - weight) + value);
                }).join(',') + ')';
                children.appendChild(document.createTextNode('\u00a0'));
                td.appendChild(children);
              }
            });
          });
          tbody.appendChild(tr);
        });
        table.appendChild(tbody);
        content.appendChild(table);
      }

      function onChooseLineEx() {
        if (document.getElementById('compare').checked) {
          if (activeLines.includes(this.value))
            return;
          activeLines.push(this.value);
          history.pushState(activeLines, '', '#' + activeLines.join('+'));
          showLines(activeLines);
        } else {
          var line = this.value;
          showLine(line);
          history.pushState(line, '', '#' + line);
        }
      }

      document.addEventListener('DOMContentLoaded', function() {
        var lineChooser = document.getElementById('lineChooser');
        lineChooser.addEventListener('change', onChooseLineEx);
        document.getElementById('resultList').addEventListener('change', onChooseLineEx);
        window.onpopstate = function(e) {
          if (e.state instanceof Array) {
            activeLines = e.state;
            showLines(activeLines);
          } else {
            showLine(e.state);
          }
        };
        document.getElementById('busid').addEventListener('input', function() {
          var query = this.value;
          if (query.length == 5)
            findBusById(query, false);
          else if (query.length == 6)
            findBusById(query, true);
        });
        lineData = JSON.parse(document.getElementById('lineData').innerHTML);
        if (location.hash.replace('#', '')) {
          var hashValue = location.hash.replace('#', '');
          if (hashValue.includes('+')) {
            activeLines = hashValue.split('+');
            showLines(hashValue.split('+'));
          } else
            showLine(lineChooser.value = hashValue);
        } else
          showLine(lineChooser.children[0].value);
      });
    </script>
  </head>
  <body>'''
#  print '<p>Choose line: </h3><select id="lineChooser">'
#  for line, linefile in lines:
#    print '<option value="%s">%s</option>' % (line, line)
#  print '''</select>
  '''      <label><input type="checkbox" id="compare">+ Compare</label>
      <span style="margin-left: 3em">
        Find bus:
        <input type="text" id="busid">
        <select size="5" id="resultList"></select>
      </span>
    </p>
    <div id="legend"></div>
    <div id="content"></div>
  </body>
</html>'''
