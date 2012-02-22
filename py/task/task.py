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

from time import time, asctime, sleep
from message import Message
from os import environ, system, getcwd
from subprocess import Popen, PIPE

from mpi import rank

from traceback import print_tb
from sys import exc_info
			
from dataaccess import DataAccess

from util import *

INVALID = -1
NEW = 0
SUCCESS = 1
FAIL = 2
ERROR = 3
WAIT = 4
RUNNING = 5

class Task(Message):
	
	_key = None
	_pid = None

	_result = None
	_start = None
	_state = None
	#_failed = None

	_root = None

	_id = None
	_slots = None

	_ready = None

	_taskname = None

	_data_access = None

	_config = None

	def __init__(self,*args,**kwargs):

		if self._statemembers == None:
			self._statemembers = []

		self._statemembers.extend( ['_result','_id','key','pid','_ready','state','_start','_root','slots','_taskname','_config'] )

		Message.__init__(self, *args, **kwargs )

		self._data_access = DataAccess( environ['STARSPATH'] + '/stars.config' )

		if len(args) >= 3:
			self.display( OUTPUT_DEBUG, 'calling initializer for Task' )
			self._initTask( args[0], args[1], args[2] )
		elif 'stateobj' in kwargs:
			self.display( OUTPUT_DEBUG, 'decoding state object for Task' )
			self._root = "%s/dep/%d/%s" % (environ['STARSPATH'], rank, self.owner )

		if not self._config == None and 'general' in self._config:
			if 'results' in self._config['general']:
				temp = self._config['general']['results'].split(':')
				if len( temp ) == 1:
					self._data_access.setStore( None, temp[0], True )
				elif len( temp ) == 2:
					self._data_access.setStore( temp[0], temp[1], None )

	def _initTask(self, owner, tid, config):
		self._config = config
		self._result = None
		self._id = "%s%d" % ( self.__class__.__name__, tid)
		self.key = None
		self.pid = owner
		self._ready = True
		#self.failed = 0
		self.state = NEW
		self._start = time()
		self._result = []
		self._root = "%s/dep/%d/%s" % (environ['STARSPATH'], rank, str(owner) )
		self.slots = 1

		self.display( OUTPUT_DEBUG, 'finished initializer for Task' )

	def __str__(self):
		return self.id()

	def target(self):
		return self._taskname

	def recover(self):

		success = len( self._result ) > 0		

		for s,h,p,f in self._result:
			try:
				success = success and self._data_access.checkStore( s, f )
			except:
				success = False

		if success:
			self.state = SUCCESS
			self._result = []
			self.display( OUTPUT_MINOR, 'recovered results' )

		return success

	def store(self):

		success = True
		self.display( OUTPUT_DEBUG, 'results %s' % str( self._result ) )
		for s,h,p,f in self._result:
			self.display( OUTPUT_DEBUG, 's %s h %s p %s f %s' % ( s,h,p,f ) )
			try:
				success = success and self._data_access.store( s,h,p,f )
			except:
				displayExcept()
				success = False

			self._data_access.remove( h, p, f )

		if not success:
			self.state = ERROR

		return success

	@property
	def key(self):
		return self._key

	@key.setter
	def key(self,value):
		if self._key == None:
			self._key = value

	@property
	def pid(self):
		return self._pid

	@pid.setter
	def pid(self,value):
		if self._pid == None:
			self._pid = value

	def id(self):
		return self._id

	def subprocess(self,cmdline,path):
		rcode = -1
		p = None
		pid = None
		try:
			if path == None:
				path = self._root

			self.display( OUTPUT_DEBUG, 'starting sub process' )
			p = Popen( cmdline, shell=True, cwd=path )
			if not p == None:
				pid = p.pid
				self.display( OUTPUT_DEBUG, 'writing pid file' )
				f = open( '%s/%d.pid' % ( self._root, pid ), 'w' )
				f.write( str(self.key) )
				f.close()

				self.display( OUTPUT_DEBUG, 'start polling for task finish or kill' )
				#while system() == 0:
				while p.poll() == None:
					if system( 'stat %s/%d.kill &> /dev/null' % ( self._root, pid ) ) == 0:
						self.display( OUTPUT_DEBUG, 'trying to shut down all child processes for pid %d' % pid ) 
						system( 'ps -o pid= --ppid %d | xargs kill -9' % pid )
						p.kill()
						self.state = ERROR
						self.display( OUTPUT_DEBUG, 'terminated running task.' )
						break

					sleep(10)

				if not p.returncode == None:
					self.display( OUTPUT_DEBUG, 'subprocess finished with code %d' % p.returncode )
					rcode = p.returncode

		except:
			displayExcept()
			self.display( OUTPUT_ERROR, 'error creating subprocess for task')
			self.state = ERROR

			if not p == None:

				p.kill()

			rcode = None
		
		if not pid == None:
			system( 'rm %s/%d.* &> /dev/null' % ( self._root, pid ) )
		
		
		return rcode

	def addResult(self,sub_path, path,name):
		f = ( sub_path, self.hostname, path, name )
		self.display( OUTPUT_DEBUG, 'result added %s:%s/%s for store:%s' % ( self.hostname, path, name, sub_path ) )
		self._result.append( f )
		
	@property
	def slots(self):
		return self._slots

	@slots.setter
	def slots(self,value):
		if value >= 0:
			self._slots = value

	@property
	def failed(self):
		return self._failed

	@failed.setter
	def failed(self,value):
		self._failed = self._failed + value
		if self._failed < 0:
			self._failed == 0
		
	def ready(self):
		return self._ready

	@property
	def state(self):
		return self._state

	@state.setter
	def state(self,value):
		if value == ERROR and not self._state == ERROR:
			self.display( OUTPUT_ERROR, '%s encountered an error' % self.id() )

		if not self._state == ERROR:
			self._state = value

	def finish(self):
		return True

	def execute(self):
		raise NotImplementedError

	def result(self):
		return self._result
		
	def display(self,level, text):
		if not self.worker == None and not self.hostname == None:
			display( level, '%s on %s: %s' % ( self.__class__.__name__, self.hostname, text) )
		else:
			display( level, '%s: %s' % ( self.__class__.__name__, text ) )

		

