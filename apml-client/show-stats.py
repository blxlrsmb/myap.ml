#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: show-stats.py
# Date: Sat Jun 06 20:16:34 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from logger import EventLogger
ev = EventLogger()
pkgs = ev.packages
names = set()
cnt = 0
for p in pkgs:
    names = names.union(set(p['key'].keys()))
    cnt += sum(p['key'].itervalues())
    names = names.union(set(p['mouse'].keys()))
    cnt += sum(p['mouse'].itervalues())
print names
print cnt
