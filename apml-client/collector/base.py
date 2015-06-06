#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: base.py
# Date: Sat Jun 06 14:57:27 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from abc import ABCMeta, abstractmethod
import logging
logger = logging.getLogger(__name__)
import threading

class APMCollectorBase(object):
    __metaclass__ = ABCMeta

    def __init__(self):
        self.stopped = False
        self.keyboard_th = None
        self.mouse_th = None

    def spawn(self):
        logger.info("Starting Collector...")
        self.keyboard_th = threading.Thread(
            target=self._collect_key, args=())
        self.keyboard_th.start()

        self.mouse_th = threading.Thread(
            target=self._collect_mouse, args=())
        self.mouse_th.start()

    def set_event_cb(self, keyboard_cb, mouse_cb):
        self._keyboard_cb = keyboard_cb
        self._mouse_cb = mouse_cb

    def on_key(self):
        window = self._get_current_window()
        self._keyboard_cb(window)

    def on_mouse(self):
        window = self._get_current_window()
        self._mouse_cb(window)

    def stop(self):
        self.stopped = True
        if self.keyboard_th:
            self.keyboard_th.join()
        if self.mouse_th:
            self.mouse_th.join()

    def __del__(self):
        if not self.stopped:
            self.stop()

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
