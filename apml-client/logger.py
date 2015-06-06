#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: logger.py
# Date: Sat Jun 06 16:32:29 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import os
import cPickle as pickle
import time
import logging
logger = logging.getLogger(__name__)

LOG_DIR = os.path.join(os.path.dirname(__file__),
                       'logs')
INCREMENT_SAVE_INTERVAL = 2

class EventLogger(object):
    def __init__(self):
        if not os.path.exists(LOG_DIR):
            os.mkdir(LOG_DIR)
        self.load_snapshot()

    def add_package(self, pack):
        self.packages.append(pack)
        if len(self.packages) > self.saved_nr_package + INCREMENT_SAVE_INTERVAL:
            self.save_snapshot()

    def load_snapshot(self):
        f = self.get_hist_file()
        if f is None:
            self.packages = []
        else:
            logger.info("Load snapshot data from {} ...".format(f))
            self.packages = pickle.load(open(f))
        self.saved_nr_package = len(self.packages)

    def save_snapshot(self):
        hists = self.get_hist_file(all=True)

        fname = os.path.join(LOG_DIR,
                             time.strftime("%Y-%m-%d-%H:%M:%S"))
        pickle.dump(self.packages, open(fname, 'w'))
        logger.info("Snapshot data saved to {}.".format(fname))
        for f in hists:
            os.unlink(f)
        self.saved_nr_package = len(self.packages)


    def get_hist_file(self, all=False):
        files = os.listdir(LOG_DIR)
        if not files:
            if not all:
                return None
            else:
                return []
        else:
            if not all:
                return os.path.join(LOG_DIR, files[-1])
            else:
                return [os.path.join(LOG_DIR, f) for f in files]

