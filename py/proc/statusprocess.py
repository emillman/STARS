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

from process import Process
from statustask import StatusTask
from time import time
from task import ERROR, SUCCESS

from util import *

class StatusProcess(Process):
	
	_last = 0
	_interval = 300
	_data = None

	def __init__(self,config,pid):
		Process.__init__(self,config,pid)
		
		self._interval = 300
		self._last = time() - self._interval
		self._data = None

		self.display( OUTPUT_VERBOSE, 'status process activated' )

	def ready(self):
		return time() - self._last >= self._interval

	def done(self):
		return self.state == ERROR

	def handle(self, task):

		if isinstance( task, StatusTask ) and task.state == SUCCESS:
			#print 'got task back'
			if self._data == None:
				self._data = {}
			#print task
			self._data[ task.worker ] = task.result()
			k = task.worker
			s = self._data[ k ]
			self.display( OUTPUT_MINOR, "Worker %d(%s): system load: %0.3f/%0.3f/%0.3f, memory free: %0.3f%%/%0.3f%%" % ( k, task.hostname, s['load'][1], s['load'][5], s['load'][15], s['memory']['phys']*100.0, s['memory']['swap']*100.0 ) )

	def task(self):
		t = None
		if not self.state == ERROR:
			t = StatusTask(self._id, 0)
			t.bcast = True
			self.queueControlTask( t )
			self._last = time()
			t = None
				
		return t

	def peek(self):
		if self.ready():
			return StatusTask(self._id, 0)
		else:
			return Process.peek(self)
