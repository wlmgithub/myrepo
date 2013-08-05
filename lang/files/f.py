import re
import pprint
from collections import defaultdict

h = defaultdict()
p = re.compile(r'(\w+)\s+(.*)')


with open("foo.txt") as fh:
  for line in fh:
    m = p.match(line)
    if m:
      k = m.group(1)
      v = m.group(2)
      if k in h:
        h[k] += int(v)
      else:  
        h[k] = int(v)

#pprint.pprint( h )
#print h.items()

for k, v in h.items():
  print "%s\t%d" % (k, v)
