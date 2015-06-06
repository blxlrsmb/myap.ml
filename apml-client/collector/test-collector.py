#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: test-collector.py
# Date: Sat Jun 06 15:00:00 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from linux import LinuxAPMCollector
import time

coll = LinuxAPMCollector([10], [13])

def kb_cb(w):
    print 'pressed ' + w
def mo_cb(w):
    print 'clicked ' + w

coll.set_event_cb(kb_cb, mo_cb)
try:
    coll.spawn()
except KeyboardInterrupt:
    coll.stop()
