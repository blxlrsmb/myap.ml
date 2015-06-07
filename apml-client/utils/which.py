#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: which.py
# Date: Sun Jun 07 00:56:11 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import os
def which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

    fpath, fname = os.path.split(program)
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None
