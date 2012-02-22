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

PROC_READY = 0
PROC_WAIT = 1
PROC_DONE = 2
PROC_STOP = 3
PROC_ERROR = 4

from os import environ

from dataaccess import DataAccess

from task import SUCCESS, ERROR

from util import *

class Process(object):

	__id__ = None
	__state__ = None	
	__context__ = None
	
	__sub_procs__ = None
	__tasks__ = None
	__out__ = None

	#__data_access__ = None
	
	def __init__(self,context,id):
		self.__context__ = context
		self.__id__ = id
		self.__state__ = PROC_READY
		self.__sub_procs__ = []
		self.__tasks__ = []
		self.__out__ = {}

		self.__data_access__ = DataAccess( environ['STARSPATH'] + '/stars.config' )

	@property
	def context(self):
		return self.__context__

	@property
	def state(self):
		return self.__state__

	@state.setter
	def state(self,value):
		if not self.__state__ == value:
			if not self.__state__ == PROC_ERROR:
				if not value == PROC_ERROR:
					self.display( OUTPUT_DEBUG, 'changed state from %d to %d' % (self.__state__, value) )
				else:
					self.display( OUTPUT_ERROR, 'encountered an error' )
				self.__state__ = value
			elif self.__state__ == PROC_ERROR and value == PROC_DONE:
				self.display( OUTPUT_ERROR, 'encountered an error and is now done' )
				self.__state__ = value

	@property
	def context(self):
		return self.__context__
	
	@property
	def tasks(self):
		return self.__tasks__

	@property
	def sub_procs(self):
		return self.__sub_procs__
	
	@property
	def out(self):
		return self.__out__
	

	def id(self):
		return self.__id__

	def getTask(self):
		task = None

		if not self.state == PROC_ERROR:
			if len( self.tasks ) > 0:
				task = self.tasks.pop(0)
				self.out[task.id()] = task
			else:
				self.display( OUTPUT_MINOR, 'no current tasks, checking sub-processes for tasks' )
				for p in range(0, len(self.__sub_procs__) ):
					proc = self.sub_procs[p]
					if proc.state == PROC_DONE:
						continue

					if proc.state == PROC_READY:
						task = proc.getTask()
						break
					
		if not task == None:
			self.display( OUTPUT_MINOR, 'issued task %s' % task.id() )
		
		self.determineState()

		return task

	def determineState(self):
		all_done = True
		any_error = False
		any_ready = False

		for p in self.sub_procs:
			# determine the state of sub-processes if not in error state
			if not self.state == PROC_ERROR:
				all_done = all_done and p.state == PROC_DONE
				any_error = any_error or p.state == PROC_ERROR
				any_ready = any_ready or p.state == PROC_READY
			# make sure sub-processes inherit the error state
			else:
				if not p.state == PROC_DONE:
					p.state = PROC_ERROR


		# the process is in the error state if a sub-process had an error
		if any_error:
			self.state = PROC_ERROR

		if self.state == PROC_ERROR:
			# the process is done when all sub-processes are done and not tasks are out
			if all_done and len( self.out ) == 0:
				self.state = PROC_DONE
		elif all_done:
			if len( self.tasks ) > 0:
				self.state = PROC_READY
			elif len( self.out ) > 0:
				self.state = PROC_WAIT
			else:
				self.state = PROC_DONE

		elif any_ready:
			self.state = PROC_READY

		elif not any_ready:
			if len( self.tasks ) > 0:
				self.state = PROC_READY
			else:
				self.state = PROC_WAIT
			
	def handle(self,task):

		if not task.id() in self.out:
			all_done = len( self.sub_procs ) > 0
			for p in range(0,len(self.sub_procs)):
				proc = self.sub_procs[p]
				old_state = proc.state
				proc.handle( task )
				all_done = all_done and proc.state == PROC_DONE
				if not proc.state == old_state and proc.state == PROC_DONE:
					self._subprocDone( p+1 )
			if all_done:
				self._subprocsDone()

		else:
			self.display( OUTPUT_MINOR, 'experiment got back task %s' % (task.id()) )
			del self.out[task.id()]	
			if task.state == SUCCESS:
				self._handleSuccess( task )
			else:
				self._handleError( task )

		self.determineState()


	def _subprocDone(self, proc):
		raise Exception('process','user must implement _subprocDone in their process')

	def _subprocsDone(self, proc):
		raise Exception('process','user must implement _subprocsDone in their process')

	def _handleSuccess(self, task):
		raise Exception('process','user must implement _handleSuccess in their process')

	def _handleError(self, task):
		raise Exception('process','user must implement _handleError in their process')

	def display(self,level,text):
		text = 'Process %d: %s - %s' % (self.id(), self.__class__.__name__, text)
		display( level, text )

	# these methods and properties are depricated
	def nextControlTask(self):
		#self.display( OUTPUT_DEBUG, 'nextControlTask is depricated' )
		return None
		#raise Exception('process','nextControlTask is a depricated function')
	
	def queueControlTask(self,task):
		#self.display( OUTPUT_DEBUG, 'queueControlTask is depricated' )
		#raise Exception('process','queueControlTask is a depricated function')	
		pass

	def peek(self):
		self.display( OUTPUT_DEBUG, 'peek is depricated' )
		#raise Exception('process','peek is a depricated function')

	def task(self):
		return self.getTask()

