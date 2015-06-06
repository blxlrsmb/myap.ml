#!/usr/bin/env python2
# -*- coding: UTF-8 -*-
# File: player.py
# Date: Sun Jun 07 00:28:19 2015 +0800
# Author: Yuxin Wu <ppwwyyxxc@gmail.com>

import os
import subprocess
import socket
import math
import time
import logging
logger = logging.getLogger(__name__)

from config import config

class MusicPlayer(object):
    def __init__(self):
        music_path = config.get('client', 'music')
        music_path = os.path.expanduser(music_path)
        self.socket_path = os.path.join('/tmp/', "socket-" + os.path.basename(music_path))
        cmd = 'mpv "{}" -vo null --input-unix-socket="{}" --loop inf > /tmp/log 2>&1'.format(
            music_path, self.socket_path)
        self.proc = subprocess.Popen(cmd, shell=True,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.paused = False

    def _create_socket(self):
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(0.1)
        s.connect(self.socket_path)
        return s

    def set_speed(self, speed):
        s = self._create_socket()
        logger.info("Set speed to {}.".format(speed))
        s.send('{{"command": ["set_property", "speed", {}]}}\r\n'.format(float(speed)))

    def set_pause(self, pause):
        if self.paused == pause:
            return
        logger.info("Set pause to {}.".format(pause))
        self.paused = pause

        s = self._create_socket()
        s.send('{{"command": ["set_property", "pause", {}]}}\r\n'.format('true' if pause else 'false'))

    def __del__(self):
        self.proc.terminate()
        os.unlink(self.socket_path)

class SpeedController(object):
    NR_EVENT_CHANGE_SPEED = 5
    MOMENTUM = 0.7
    MAX_SPEED = config.getfloat('client', 'max_music_speed')
    SPEED_SILENCE_THRES = config.getfloat('client', 'silence_threshold')

    def __init__(self):
        self.last = time.time()
        self.cnt = 0
        self.player = MusicPlayer()
        self.last_speed = 0.0

    def on_event(self):
        self.cnt = (self.cnt + 1) % self.NR_EVENT_CHANGE_SPEED
        if self.cnt == 0:
            now = time.time()
            interval = now - self.last
            self.last = now
            speed = self.NR_EVENT_CHANGE_SPEED / float(interval)
            speed = self.MAX_SPEED * (1 - math.exp(-speed / 4))
            self.update_speed(speed)

    def update_speed(self, speed):
        speed = self.last_speed * self.MOMENTUM + speed * (1 - self.MOMENTUM)
        print "speed, last:", speed, self.last_speed
        self.last_speed = speed
        if speed < self.SPEED_SILENCE_THRES:
            self.player.set_pause(True)
        else:
            self.player.set_pause(False)
            self.player.set_speed(speed)

    def zero_speed(self):
        self.update_speed(0.0)

if __name__ == '__main__':
    player = MusicPlayer()
    import time
    time.sleep(3)
    player.set_speed(0.1)
    time.sleep(3)
    player.set_pause(True)
    time.sleep(3)
    player.set_pause(False)
    player.set_speed(1)
    time.sleep(3)
