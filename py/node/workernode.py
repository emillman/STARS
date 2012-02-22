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
from task import Task, NEW, FAIL, SUCCESS, ERROR
from controltask import ControlTask
from multiprocessing import Pool, cpu_count, Pipe
from multiprocessing.reduction import reduce_connection
from sys import path
from os import environ, listdir

import pickle


from util import *

def handle_task(ppipe):
	display( OUTPUT_DEBUG, 'unpickling the connection' )
	upw = pickle.loads(ppipe) # unpickled writer
    	pipe = upw[0](upw[1][0],upw[1][1],upw[1][2])
	task = None
	try:
		root = pipe.recv()
		if path.count( root ) == 0:
			display( OUTPUT_DEBUG, 'updated path' )
			path.insert( 0, root )

		files = listdir( root )
		for f in files:
			#print f
			if f.endswith( '.py' ):
				module = __import__( f.split('.')[0] )
				reload( module )

		task = pipe.recv()

		display( OUTPUT_DEBUG, 'process pool running task %s' % task.id() )
		task.execute()

		if path.count( root ) > 0:
			display( OUTPUT_DEBUG, 'removing path from process' )
			path.remove( root )

	except:
		displayExcept()
		if task == None:
			display( OUTPUT_ERROR, 'process in pool encountered an error' )
		else:
			display( OUTPUT_ERROR, 'task in process pool had an error %s' % str( task ) )
			task.state = ERROR 

	return task

class WorkerNode(MPINode):

	_pool = None
	_poolsize = 0
	_inuse = 0
	_procs = None
	_pipes = None
	#_manager = None

	def __init__(self):
		MPINode.__init__(self, self.poll_handler )
		
		self._procs = {}
		self._pipes = {}
		#self._queues = {}
		#self._manager = Manager()
		self._poolsize = self._cpu_cores
		
		self._inuse = 0
		self._pool = Pool( processes=self._poolsize )

	def handle(self, task):
		result = False
		if isinstance(task, Task):
			self.display( OUTPUT_DEBUG, 'task to handle %s' % task.id() )
			result = True
			if task.state == NEW:
				task.worker = self._rank
				task.hostname = self._name

				if isinstance( task, ControlTask ):
					self.display( OUTPUT_DEBUG, 'running command task locally' )
					task.execute()
					result = self.handle( task )

				elif task.pid in self._procs:
					if (self._inuse + task.slots) <= self._poolsize:
						self.display( OUTPUT_DEBUG, 'running task with process pool' )
						rp, lp = Pipe(False)
						lp.send( self._procs[ task.pid ] )
						lp.send( task )
						self._pipes[ task.key ] = ( rp, lp )
						tmp = pickle.dumps(reduce_connection(rp))
						h = self._pool.apply_async( handle_task, (tmp,) )

						self._pollq.append( h )
						self._inuse = self._inuse + task.slots
						self.display( OUTPUT_DEBUG, 'using: %d, task used %d' % ( self._inuse, task.slots) )
						
				
					elif self._inuse == 0 and self._poolsize < task.slots:
						self.display( OUTPUT_DEBUG, 'running oversized task with process pool' )
						rp, lp = Pipe(False)
						lp.send( self._procs[ task.pid ] )
						lp.send( task )
						self._pipes[ task.key ] = ( rp, lp )
						tmp = pickle.dumps(reduce_connection(rp))
						h = self._pool.apply_async( handle_task, (tmp,) )

						self._pollq.append( h )
						self._inuse = self._inuse + task.slots
						self.display( OUTPUT_DEBUG, 'using: %d, task used %d' % ( self._inuse, task.slots) )
		
					else:
						self.display( OUTPUT_DEBUG, 'no processes available to run task' )
						self.queueFirst( task )
						result = False
				else:
					self.display( OUTPUT_DEBUG, 'process resources not available on worker yet' )
					self.queueFirst( task )
					result = False
							
					
			else:
				self.display( OUTPUT_DEBUG, 'returning task to manager' )
				self.returnTask( task )
		else:
			self.display( OUTPUT_DEBUG, 'got invalid task to handle' )
					
		return result

	def poll_handler(self, result):
		if result.ready():
			self.display( OUTPUT_DEBUG, 'task from pool completed' )
			task = result.get()				

			if not task == None:
				self.display( OUTPUT_DEBUG, 'task is valid' )
				if task.key in self._pipes:
					self.display( OUTPUT_DEBUG, 'removing pipes from list' )
					del self._pipes[task.key]

				self._inuse = self._inuse - task.slots
				if self._inuse < 0:
					self._inuse = 0

				self.display( OUTPUT_DEBUG, 'using: %d, task freed %d' % ( self._inuse, task.slots) )
				self.handle( task )
				return True
		return False
