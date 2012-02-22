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

from mpi import irecv, isend, rank, allgather
from task import Task, NEW, SUCCESS, ERROR, INVALID
from controltask import ControlTask
from commands import getoutput
from os import environ, system
from sys import exc_info
from multiprocessing import cpu_count
from time import asctime

from traceback import print_tb

from dataaccess import DataAccess

from util import *

class MPINode:
	
	_rank = -1
	_name = None
	_done = False

	_msgq = None
	_pollq = None
	_pollfunc = None

	_recv = None
	_send = None
	
	_root = None
	_workers = None

	_data_access = None

	_cpu_cores = None


	def __init__(self, pollfunc):
		self._done = False
		self._rank = rank
		self._msgq = []
		self._pollq = []
		self._root = environ['STARSPATH']

		self._data_access = DataAccess( 'stars.config' )

		# share everyone's name with everone, so we can scp and other such goodies
		
		self._name = self._data_access._host
			
		self._workers = {}
		
		self._cpu_cores = cpu_count()
		if 0 == system( 'stat cpu_ht &> /dev/null' ):
			self._cpu_cores = int(cpu_count()/2)
			self.display( OUTPUT_DEBUG, 'cpus have HT lowering to %d cpus' % self._cpu_cores )
		elif 0 == system( 'stat cpu_one &> /dev/null' ):
			self._cpu_cores = 1
			self.display( OUTPUT_DEBUG, 'altering detected %d cpus to %d cpus' % ( cpu_count(), self._cpu_cores ) )

		workers = allgather( (self._rank, self._name, self._cpu_cores ) )
		#print workers
		w = 3
		while w < len( workers ):
			self._workers[ workers[w] ] = { 'name': workers[w+1], 'mslots': workers[w+2], 'slots': workers[w+2], 'proc': [], 'reserved':False }
			w = w + 3

		if not pollfunc == None:
			self._pollfunc = pollfunc

		self._recv = irecv()
		self._send = True

		self.display( OUTPUT_VERBOSE, 'initialized on %s' % self._name )

	@property
	def workers(self):
		return self._workers

	@property
	def worker(self):
		return self._rank

	@property
	def hostname(self):
		return self._name		

	def queue(self,msg):
		self.display( OUTPUT_VERBOSE, 'received task to place at end of queue' )
		self._msgq.append( msg )

	def queueFirst(self,msg):
		self.display( OUTPUT_VERBOSE, 'received task to place at front of queue' )
		self._msgq.insert( 0, msg )

	def done(self):
		return self._done

	def step(self):
		#self.display( OUTPUT_VERBOSE, 'performing step' )
		result = True
		task = None
		try:
			if not self._pollfunc == None:
				self.poll()

			if not self._done:
				#print 'looping node step'
				old_size = len( self._msgq )
				self.recv()
				while old_size < len( self._msgq ):
					self.display( OUTPUT_DEBUG, 'got waiting message' )
					old_size = len( self._msgq )
					self.recv()


				task = self.next()

				if isinstance( task, Task ):
					self.display( OUTPUT_VERBOSE, 'got new task to perform' )
					if isinstance( task, ControlTask ):
						self.display( OUTPUT_DEBUG, 'node associated to control task' )
						task.node = self

					self.display( OUTPUT_VERBOSE, 'handling task %s' % task.id() )
					result = self.handle( task )
				else:
					result = False

			#if not self._pollfunc == None:
			#	self.poll()
		except:
			self.display( OUTPUT_ERROR,'encountered error processing message')
			displayExcept()
			result = False
			if not task == None and isinstance(task,Task):
				task.state = ERROR
				self.handle( task )


		return result

	def poll(self):
		self.display( OUTPUT_VERBOSE, 'running poll function' )
		l = len( self._pollq )
		i = 0

		while i < l:
			if self._pollfunc(self._pollq[i]):
				self.display( OUTPUT_VERBOSE, 'removed item from poll' )
				del self._pollq[i]
				break
			i = i + 1

	def returnTask(self,task):
		self.display( OUTPUT_DEBUG, 'returning task to node 0 %s' % str( task ) )
		self.send( task )

	def send(self, task, dest=0):
		#print 'sending task'
		if isinstance( task, Task ):
			
			if dest == rank:
				self.display( OUTPUT_MPI, 'cannot send task to self %s' % task.id() )
				self.queue( task )
				
			elif not dest == None:
				if isinstance( task, ControlTask ):
					self.display( OUTPUT_DEBUG, 'removing node associated for control task' )
					task.node = None

				data = task.encodeTask()

				if type(dest) is int:
					if self._send:
						self._send = isend( data, dest )
						self.display( OUTPUT_DEBUG, 'sent task %s to node %d' % (task.id(),dest) )

				else:
					for d in dest:
						if self._send:
							self._send = isend( data, d )
							self.display( OUTPUT_DEBUG, 'sent task %s to node %d' % (task.id(),d) )
						else:
							self._send.wait()				

	def recv(self):
		try:
			if self._recv:
				self.display( OUTPUT_DEBUG, 'incoming message from node %d' % self._recv.status.source )
				module = __import__( self._recv.message['class'].lower() )
				task = eval( "module.%s(stateobj=%s)" % ( self._recv.message['class'], self._recv.message) )
				dest = self._recv.status.source
				self.display( OUTPUT_DEBUG, 'received task %s from node %d' % (task.id(),dest) )
				task.sender = dest
				task.hostname = self._name
				if isinstance( task, ControlTask ):
					task.node = self
					self.queueFirst( task )

				elif task.state == NEW:
					self.queue( task )
				else:
					self.queueFirst( task )
				self._recv = irecv()
		except:
			displayExcept()
			self.display( OUTPUT_ERROR, 'failed to receive incoming task' )
			self._recv = irecv()
			

	def handle(self, task):
		raise NotImplementedError

	def next(self):
		task = None
		#print self._msgq
		if len( self._msgq ) > 0:
			task = self._msgq.pop(0)
		return task

	def finish(self):
		return
		
	def display(self, level, text):
			if self._rank == 0:
				display( level, 'Manager %d(%s): %s' % (self._rank, self._name, text) )
			else:
				display( level, 'Worker %d(%s): %s' % (self._rank, self._name, text) )
