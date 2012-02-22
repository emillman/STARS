# Copyright (C) 2011 Eamon Millman
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
#

from task import Task, NEW, SUCCESS, ERROR, FAIL, INVALID
from time import time, sleep
from random import random
from subprocess import Popen, PIPE
from controltask import ControlTask
from multiprocessing import Process, Queue, Value, Lock
from os import system

from cltsutils import *

class RandomTestTask(Task):

	_max = None

	def __init__(self,*args,**kwargs):

		self._statemembers = ['_max']

		Task.__init__(self, *args, **kwargs )

		if len(args) == 4:
			self.display( OUTPUT_DEBUG, 'calling initializer for TestTask' )
			self._initRandomTestTask( args[0], args[1], args[3] )

	def _initRandomTestTask(self, owner, tid, max):

		self._max = max
		r = random()
		
		if r < 0.05:
			self.slots = 5
			self._taskname = '%s%d' % ( 'BigTestTask', tid )

		self.display( OUTPUT_DEBUG, 'finished initializer for TestTask' )

	def execute(self):
		sleep = random()*self._max
		self.display( OUTPUT_DEBUG, 'running test task sleeping for %f seconds' % sleep )
		self.subprocess( 'sleep %f' % sleep, None )
		r = random()
		if r < 0.01:
			raise Exception('test','exception')
		elif r < 0.05:
			self.state = ERROR
		elif r < 0.06:
			self.state = NEW
		elif r < 0.07:
			self.state = INVALID
		elif r < 0.09:
			self.state = FAIL
		else:
			self.state = SUCCESS

			
"""
	def subprocess(self, cmdline, path):
		r = random()
		if r < 0.90:
			Task.subprocess(self, cmdline, path)
		else:
			system('touch %s/%s.pid &> /dev/null' % ( self._root, str(r) ) )
			while not system( 'stat %s/%s.kill &> /dev/null' )  == 0:
				sleep(0.25)

			if r < 0.95:
				system('rm %s/%s.* &> /dev/null' % ( self._root, str(r) ) )
			else:
				self.display('faking un responsive process')
"""
