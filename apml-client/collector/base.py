#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: base.py
# Date: Sat Jun 06 15:16:49 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from abc import ABCMeta, abstractmethod
import logging
logger = logging.getLogger(__name__)
import threading
import time

class APMCollectorBase(object):
    __metaclass__ = ABCMeta

    def __init__(self):
        self.stopped = False
        self.keyboard_th = None
        self.mouse_th = None

    def spawn(self):
        logger.info("Starting Collector...")
        self.keyboard_th = threading.Thread(
            target=self.collect_key, args=())
        self.keyboard_th.start()

        self.mouse_th = threading.Thread(
            target=self.collect_mouse, args=())
        self.mouse_th.start()

    def set_event_cb(self, keyboard_cb, mouse_cb):
        self._keyboard_cb = keyboard_cb
        self._mouse_cb = mouse_cb

    def on_key(self):
        t = time.time()
        window = self._get_current_window()
        self._keyboard_cb(t, window)

    def on_mouse(self):
        t = time.time()
        window = self._get_current_window()
        self._mouse_cb(t, window)

    def stop(self):
        self.stopped = True
        if self.keyboard_th:
            self.keyboard_th.join()
        if self.mouse_th:
            self.mouse_th.join()

    def __del__(self):
        if not self.stopped:
            self.stop()

    def collect_key(self):
        logger.info("Collecting key events...")
        self._collect_key()

    def collect_mouse(self):
        logger.info("Collecting mouse events...")
        self._collect_mouse()

    @abstractmethod
    def _collect_key(self):
        """ key collector worker"""
        pass

    @abstractmethod
    def _collect_mouse(self):
        """ mouse collector worker"""
        pass

    @abstractmethod
    def _get_current_window(self):
        """ get current active window"""
        pass
