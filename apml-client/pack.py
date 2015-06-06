#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: pack.py
# Date: Sat Jun 06 16:35:44 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from collections import defaultdict

class EventPacker(object):
    """ Only record and pack result in a time interval"""

    def __init__(self):
        self.key_cnt = defaultdict(int)
        self.mouse_cnt = defaultdict(int)
        self.last_time = None
        self.start = None

    def count(self):
        return sum(self.key_cnt.itervalues()) \
                + sum(self.mouse_cnt.itervalues())

    def add_key(self, time, window):
        if not self.start:
            self.start = time
        self.last_time = time

        self.key_cnt[window] += 1

    def add_mouse(self, time, window):
        if not self.start:
            self.start = time
        self.last_time = time

        self.mouse_cnt[window] += 1

    def dump(self):
        dic = {'mouse': dict(self.mouse_cnt),
               'key': dict(self.key_cnt),
               'start': self.start,
               'end': self.last_time}
        return dic
