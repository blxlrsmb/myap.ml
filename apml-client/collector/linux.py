#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: linux.py
# Date: Sat Jun 06 15:00:58 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

from .base import APMCollectorBase
import subprocess

# TODO test device correctness?
class LinuxAPMCollector(APMCollectorBase):
    def __init__(self, key_xinput_devices, mouse_xinput_devices):
        """ currently only use one device"""
        # TODO monitor multiple device at the same time
        super(LinuxAPMCollector, self).__init__()
        self.kb_device = int(key_xinput_devices[0])
        self.mo_device = int(mouse_xinput_devices[0])

    def _collect_key(self):
        proc = subprocess.Popen(
            ["xinput", "test", str(self.kb_device)],
            stdout=subprocess.PIPE)
        stdout = proc.stdout
        while not self.stopped:
            line = stdout.readline()
            if not line:
                break
            if line[4] == 'p':  # press
                self.on_key()

    def _collect_mouse(self):
        proc = subprocess.Popen(
            ["xinput", "test", str(self.mo_device)],
            stdout=subprocess.PIPE)
        stdout = proc.stdout
        while not self.stopped:
            line = stdout.readline()
            if not line:
                break
            if line[0] == 'b' and line[7] == 'p':  # button press
                self.on_mouse()

    def _get_current_window(self):
        p = subprocess.Popen("xprop -id $(xdotool getactivewindow) | grep 'WM_CLASS'",
                            shell=True, stdout=subprocess.PIPE)
        out = p.stdout.readlines()
        return out[0].split('=')[-1].split(',')[-1][2:-2]

if __name__ == '__main__':
    coll = LinuxAPMCollector(10)
    print coll._get_current_window()
