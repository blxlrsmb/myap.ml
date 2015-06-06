#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: apmldaemon.py
# Date: Sun Jun 07 00:39:49 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import platform
from Queue import Empty as EmptyException
from multiprocessing import Queue
import time

from config import config
from utils import logconf
from collector.linux import LinuxAPMCollector
from pack import EventPacker
from logger import EventLogger
from player import SpeedController

import logging
logger = logging.getLogger(__name__)

COLLECT_INTERVAL = 5

class APMLDaemon(object):
    TYPE_KEY = 0
    TYPE_MOUSE = 1

    def __init__(self):
        self.packer = EventPacker()
        system = platform.system()
        if system == 'Linux':
            # XXX TODO automatically determine device number
            key_devices = map(int, config.get('client',
                                              'linux_key_device').split(','))
            mouse_devices = map(int, config.get('client',
                                              'linux_mouse_device').split(','))
            self.coll = LinuxAPMCollector(key_devices, mouse_devices)
        else:
            raise NotImplementedError()

        self.music = SpeedController()

        self.coll.set_event_cb(
            self.on_key,
            self.on_mouse)

        self.q = Queue()
        self.logger = EventLogger()

    def start(self):
        self.coll.spawn()   # start collector

        while True:
            # process events
            tp = None
            try:
                tp, t, window = self.q.get(timeout=COLLECT_INTERVAL)
            except EmptyException:
                self.music.zero_speed()
                t = time.time()
            pack_start = self.packer.start
            if pack_start is not None \
               and t - pack_start > COLLECT_INTERVAL:
                # this sample should start a new pack
                self.pack()
            if tp is None:
                continue
            self.music.on_event()
            if tp == self.TYPE_KEY:
                self.packer.add_key(t, window)
            else:
                self.packer.add_mouse(t, window)

    def pack(self):
        dump = self.packer.dump()
        cnt = self.packer.count()
        logger.info("Pack a package of {} events".format(cnt))
        self.packer = EventPacker()
        self.logger.add_package(dump)

    def on_key(self, time, window):
        self.q.put((self.TYPE_KEY, time, window))

    def on_mouse(self, time, window):
        self.q.put((self.TYPE_MOUSE, time, window))

if __name__ == '__main__':
    d = APMLDaemon()
    d.start()
