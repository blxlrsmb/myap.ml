#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: test-collector.py
# Date: Sat Jun 06 15:16:31 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from linux import LinuxAPMCollector
import time

coll = LinuxAPMCollector([10], [13])

def kb_cb(t, w, key):
    print 'pressed ', t, w
def mo_cb(t, w):
    print 'clicked ', t, w

coll.set_event_cb(kb_cb, mo_cb)
try:
    coll.spawn()
    #time.sleep(1)
except KeyboardInterrupt:
    print 'interrupt'
    coll.stop()
