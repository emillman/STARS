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

from mpinode import MPINode, rank
from random import random
from time import time
from os import listdir, remove, mkdir, path, rename, getcwd, chdir
from sys import exc_info

from util import *

from task import Task, NEW, FAIL, SUCCESS, ERROR
from controltask import ControlTask

from processmanager import ProcessManager
from resourcemanager import ResourceManager
from workfilehandler import WorkfileHandler
from infowriter import InfoWriter

class ManagerNode(MPINode):
	
	_pm = None
	_rm = None
	_wh = None
	_iw = None

	_waiting = None

	def __init__(self):
		MPINode.__init__(self, self.poll_handler)

		self._pm = ProcessManager( {'hostname':self._name} )
		self._rm = ResourceManager( self, self._pm )
		self._wh = WorkfileHandler( None, self._rm, self._pm )
		self._iw = InfoWriter( None, self._rm, self._pm, self )
		self._waiting = {}

		self._pollq.append( self._wh )
		self._pollq.append( self._rm )
		self._pollq.append( self._iw )

		self.display( OUTPUT_DEBUG, 'initialized' )
			
		
	def returnTask(self, task):
		self.display( OUTPUT_DEBUG, 'returning task to resource manager' )
		if isinstance( task, ControlTask ):
			self.display( OUTPUT_DEBUG, 'removing node associated for control task' )
			task.node = None

		self._rm.returnTask( task )

	def handle(self, task):
		result = False
		if isinstance(task,Task):
			result = True
			#self.display( OUTPUT_DEBUG, 'task has state %d' % task.state )
			if task.state == NEW:
				self.display( OUTPUT_DEBUG, 'got task to handle %s' % task.id() )
				if isinstance( task, ControlTask ):	
					if task.bcast:
						self.display( OUTPUT_DEBUG, 'task is broadcast, sending to all workers' )
						task.destination = self._workers.keys()

				if not task.destination == None:
					if isinstance( task, ControlTask ):
						self.display( OUTPUT_DEBUG, 'sending control task directly to worker(s)' )
						self.send( task, task.destination )

					else:
						
						if not task.key in self._waiting:

							#self._workers[task.destination]['slots'] = self._workers[task.destination]['slots'] - task.slots
							#self.display( OUTPUT_DEBUG, 'slots: %d, task used %d' % (self._workers[task.destination]['slots'], task.slots) )

							if self._workers[task.destination]['proc'].count( task.pid ) > 0:
								self.display( OUTPUT_DEBUG, 'sending task to worker' )
								self.send( task, task.destination )

							else:
								self.display( OUTPUT_DEBUG, 'holding task untill resource deployment is complete' )
								self._waiting[ task.key ] = task
								self.queueFirst( task )
								result = False

						elif self._workers[task.destination]['proc'].count( task.pid ) > 0:
							del self._waiting[task.key]
							self.display( OUTPUT_DEBUG, 'sending task to worker' )
							self.send( task, task.destination )

						else:
							self.display( OUTPUT_DEBUG, 'holding task untill resource deployment is complete' )
							self.queueFirst( task )
							result = False



				else:
					self.display( OUTPUT_ERROR, 'task not given a destination and is not broadcast' )
					self.returnTask( task )
					result = False

			else:
				self.display( OUTPUT_DEBUG, 'got task back from a worker' )
				#if task.sender in self._workers:
					#self._workers[task.sender]['slots'] = self._workers[task.sender]['slots'] + task.slots

					#if self._workers[task.sender]['slots'] > self._workers[task.sender]['mslots']:
					#	self._workers[task.sender]['slots'] = self._workers[task.sender]['mslots']

					#self.display( OUTPUT_DEBUG, 'slots: %d, task freed %d' % (self._workers[task.sender]['slots'], task.slots) )

				if isinstance( task, ControlTask ):
					self.display( OUTPUT_DEBUG, 'calling finish on control task' )
					if not task.state == ERROR:
						if task.finish() == True:
							self.returnTask( task )

				else:
					self.returnTask( task )
		else:
			self.display( OUTPUT_ERROR, 'got invalid task to handle' )
					
		return result
		
	def finish(self):
		self._iw.step()
		MPINode.finish(self)

	def poll_handler(self, obj):
		obj.step()
		
		return False

