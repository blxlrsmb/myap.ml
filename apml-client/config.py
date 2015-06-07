#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: config.py
# Date: Sun Jun 07 00:42:58 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from ConfigParser import ConfigParser
import os
config = ConfigParser()
config.read(
    os.path.join(
        os.path.dirname(__file__), 'default.cfg'))
config.read(
    os.path.join(
        os.path.dirname(__file__), 'apml.cfg'))
