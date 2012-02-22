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

from process import Process, PROC_ERROR
from randomtesttask import RandomTestTask
from testcontroltask import TestControlTask
from time import time
from random import random
from task import ERROR, SUCCESS, FAIL

from cltsutils import *

class RandomTestProcess(Process):
	
	_period = None
	_start = None
	_tasktime = None
	_ctrltasktime = None
	_nextid = None
	_maxtasks = None

	def __init__(self,context,pid):
		Process.__init__(self,context,pid)

		if 'config' in context:
			self._config = context['config']
			#display( OUTPUT_DEBUG, str(self.__config__) )
		else:
			raise Exception('RandomTestProcess','no config found in context.')
		
		self._start = time()
		self._tasktime = 1
		self._nextid = 0

		if 'process' in self._config:

			if 'tasktime' in self._config['process']:
				self._tasktime = float(self._config['process']['tasktime'])

			if 'period' in self._config['process']:
				self._period = float(self._config['process']['period'])

			if 'ctrltasktime' in self._config['process']:
				self._ctrltasktime = float(self._config['process']['ctrltasktime'])

			if 'maxtasks' in self._config['process']:
				self._maxtasks = int(self._config['process']['maxtasks'])
	
		self.__queueRandomTestTask__(10)
		self.determineState()

	def __queueRandomTestTask__(self, count):
		from randomtesttask import RandomTestTask

		for c in xrange(count):
			task = RandomTestTask( self.id(), self._nextid, self._config, self._tasktime*10  )
			self._nextid = self._nextid + 1
			self.tasks.append( task )

	def _handleSuccess(self,task):
		from randomtesttask import RandomTestTask
		
		if isinstance( task, RandomTestTask ):

			self.display( OUTPUT_MINOR, 'RandomTestTask completed' )
			self.__queueRandomTestTask__(1)
			self.determineState()
		
		return
		
	def _handleError(self,task):
		self.state = PROC_ERROR

		return
