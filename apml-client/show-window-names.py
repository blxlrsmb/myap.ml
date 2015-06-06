#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: show-window-names.py
# Date: Sat Jun 06 16:59:06 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from logger import EventLogger
ev = EventLogger()
pkgs = ev.packages
names = set()
for p in pkgs:
    names = names.union(set(p['key'].keys()))
    names = names.union(set(p['mouse'].keys()))
print names
