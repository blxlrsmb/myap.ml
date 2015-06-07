#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: logger.py
# Date: Sun Jun 07 15:53:06 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import os
import cPickle as pickle
import time
import logging
import json
logger = logging.getLogger(__name__)
import requests

from config import config
LOG_DIR = os.path.join(os.path.dirname(__file__),
                       config.get('client', 'log_dir'))
INCREMENT_SAVE_INTERVAL = config.getint('client', 'save_interval')

MAX_NR_PACKAGE_SEND = 20
REQUEST_TIMEOUT = 1

class RemoteSyncing(object):
    def __init__(self):
        self.baseurl = config.get('server', 'host')
        self.userid = config.get('server', 'userid')
        self.password = config.get('server', 'password')
        self.url = "http://{}/client/{}".format(self.baseurl, self.userid)
        logger.info("Use server url: {}".format(self.url))

        self.req_header = {'Content-Type': 'application/json'}

    def send(self, packages):
        data = json.dumps({
                'password': self.password,
                'data': packages })
        try:
            r = requests.request('POST', self.url, data=data,
                headers=self.req_header, timeout=REQUEST_TIMEOUT)
            if r.status_code == 200:
                return True
        except Exception as e:
            logger.error("Error sync to server: {}".format(e))
        return False

class EventLogger(object):
    def __init__(self):
        if not os.path.exists(LOG_DIR):
            os.mkdir(LOG_DIR)
        self.last_synced_timestamp = 0
        self.last_synced_pkgidx = 0
        self.sync = RemoteSyncing()

        self.load_snapshot()
        self.update_synced_pkgidx()

    def try_send(self):
        """ try to send from last_synced_timestamp, until failed"""
        while True:
            to_send = self.packages[self.last_synced_pkgidx:
                                    self.last_synced_pkgidx + MAX_NR_PACKAGE_SEND]
            len_to_send = len(to_send)
            if not len_to_send:
                break
            succ = self.sync.send(to_send)
            if succ:
                logger.info("Successfully synced {} packages.".format(len_to_send))
                self.last_synced_pkgidx += len_to_send
                self.last_synced_timestamp = to_send[-1]['end']
            else:
                break

    def update_synced_pkgidx(self):
        for idx, p in enumerate(self.packages):
            if p['end'] >= self.last_synced_timestamp:
                self.last_synced_pkgidx = idx
                break
        logger.info("Synced package index: {}".format(self.last_synced_pkgidx))

    def add_package(self, pack):
        self.packages.append(pack)
        if len(self.packages) >= self.saved_nr_package + INCREMENT_SAVE_INTERVAL:
            self.save_snapshot()
        self.try_send()

    def load_snapshot(self):
        f = self.get_hist_file()
        if f is None:
            self.packages = []
        else:
            obj = pickle.load(open(f))
            self.packages = obj['packages']
            self.last_synced_timestamp = obj.get('last_synced_timestamp', 0)
            logger.info("Loaded {} packages from {}.".format(len(self.packages), f))
        self.saved_nr_package = len(self.packages)

    def save_snapshot(self):
        hists = self.get_hist_file(all=True)

        fname = os.path.join(LOG_DIR,
                             time.strftime("%Y-%m-%d-%H:%M:%S"))
        obj = {'packages': self.packages,
               'last_synced_timestamp': self.last_synced_timestamp}
        pickle.dump(obj, open(fname, 'w'))
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
