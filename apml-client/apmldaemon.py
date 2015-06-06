#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: apmldaemon.py
# Date: Sat Jun 06 17:02:21 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import platform
from multiprocessing import Queue

from utils import logconf
from collector.linux import LinuxAPMCollector
from pack import EventPacker
from logger import EventLogger

import logging
logger = logging.getLogger(__name__)

TYPE_KEY = 0
TYPE_MOUSE = 1

COLLECT_INTERVAL = 5

class APMLDaemon(object):
    def __init__(self):
        self.packer = EventPacker()
        system = platform.system()
        if system == 'Linux':
            # XXX TODO automatically determine device number
            self.coll = LinuxAPMCollector([10], [13])
        else:
            raise NotImplementedError()
        self.coll.set_event_cb(
            self.on_key,
            self.on_mouse)

        self.q = Queue()
        self.logger = EventLogger()

    def start(self):
        self.coll.spawn()
        while True:
            tp, time, window = self.q.get()
            last_time = self.packer.start
            if last_time is not None \
               and time - last_time > COLLECT_INTERVAL:
                self.pack()
            if tp == TYPE_KEY:
                self.packer.add_key(time, window)
            else:
                self.packer.add_mouse(time, window)

    def pack(self):
        dump = self.packer.dump()
        cnt = self.packer.count()
        assert cnt
        logger.info("Pack a package of {} events".format(cnt))
        self.packer = EventPacker()
        self.logger.add_package(dump)

    def on_key(self, time, window):
        self.q.put((TYPE_KEY, time, window))

    def on_mouse(self, time, window):
        self.q.put((TYPE_MOUSE, time, window))

if __name__ == '__main__':
    d = APMLDaemon()
    d.start()