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

from controltask import ControlTask
from task import NEW, SUCCESS, ERROR, FAIL

from os.path import split, exists
from os import mkdir, path, getcwd, chdir, remove, listdir, system, environ, stat
from shutil import rmtree, move
from tarfile import TarFile
from sys import path, exc_info
from time import time, sleep

from util import *

class KillTask(ControlTask):

	_target = None

	def __init__(self,*args,**kwargs):

		self._statemembers = ['_target']

		ControlTask.__init__(self, *args, **kwargs )

		if len(args) == 4:	
			self.display( OUTPUT_DEBUG, 'calling initializer for KillTask' )
			self._initKillTask( args[3] )

	def _initKillTask(self, target):
		self._target = target
		#self._bcast = True
		self.display( OUTPUT_DEBUG, 'finished initializer for KillTask' )

	def execute(self):
		self.display( OUTPUT_DEBUG, 'running kill task' )
		self.state = FAIL
		try:
			files = listdir( self._root )
			for f in files:
				if f.endswith( '.pid' ):
					try:
						self.display( OUTPUT_DEBUG, 'checking %s for target task' % f ) 
						fi = open( '%s/%s'% ( self._root, f ) )
						info = fi.read()
						fi.close()
				
						if info == str(self._target):
							if system( 'touch %s/%s.kill &> /dev/null' % ( self._root, f.split('.')[0] ) ) == 0:
								self.display( OUTPUT_DEBUG, 'task %s asked to terminate.' % str(self._target) )
								self.state = SUCCESS

						t = time()
						while system( 'stat %s/%s.kill &> /dev/null' % ( self._root, f.split('.')[0] ) ) == 0:
						
							if not system( 'stat %s/%s.pid &> /dev/null' % ( self._root, f.split('.')[0] ) ) == 0:
								self.display( OUTPUT_DEBUG, 'task %s ended before termination' % info )
								break

							sleep(0.25)

							if time() - t > 10:
								self.display( OUTPUT_ERROR, 'task %s did not respond to kill request.' % info )
								self.state = ERROR
								break

				

					except:
						if str(self._target) == f.split('.')[0]:
							self.display( OUTPUT_DEBUG, 'task ended durring termination' )
							self.state = SUCCESS
						continue

		except:
			self.display( OUTPUT_ERROR, 'error accessing resources path')
			self.state = ERROR

		# if not currently running check for it in the message queue
		if self.state == FAIL:
			self.display( OUTPUT_DEBUG, 'checking worker task queue' )
			done = []

			for task in self.node._msgq:

				if task.key == self._target:

					done.append( task )

			for task in done:

				self.node._msgq.remove( task )
				task.state = ERROR
				self.node.returnTask( task )
				self.display( OUTPUT_DEBUG, 'removed task from processing queue')
				self.state = SUCCESS

	def finish(self):
		
		# in not on a worker check queue on master
		if self.state == FAIL:
			self.display( OUTPUT_LOGIC, 'checking manager task queue' )
			done = []

			for task in self.node._msgq:

				if task.key == self._target:

					done.append( task )

			for task in done:

				self.node._msgq.remove( task )
				task.state = ERROR
				self.node.returnTask( task )
				self.display( OUTPUT_DEBUG, 'removed task from processing queue')
				self.state = SUCCESS

		return self.state == SUCCESS or self.state == ERROR
		
