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

from time import time

from util import *

INVALID = -1
NEW = 0
SUCCESS = 1
ERROR = 2

class Message(object):
	
	_sender = None
	_destination = None
	_task = None
	_worker = None
	_hostname = None
	_bcast = False

	_statemembers = None
	
	_owner = None
	
	def __init__(self,*args,**kwargs):

		if self._statemembers == None:
			self._statemembers = []

		self._statemembers.extend( ['sender','destination','_task','worker','hostname','bcast','owner'] )

		if len( args ) >= 1:
			self.display( OUTPUT_DEBUG, 'calling initializer for Message' )
			self._initMessage( args[0] )

		elif 'stateobj' in kwargs:
			self.display( OUTPUT_DEBUG, 'decoding state object for Message' )
			self.decodeTask( kwargs['stateobj'] )

	def _initMessage(self,owner):
		self.owner = owner
		self.destination = None
		self.sender = None
		self._task = None
		self.worker = None
		self.hostname = None
		self.bcast = False
		self.display( OUTPUT_DEBUG, 'finished initializer for Message' )

	def encodeTask(self):
		stateobj = {}
		stateobj['class'] = self.__class__.__name__
		stateobj['state'] = {}

		for i in self._statemembers:
			#print 'saving %s' % i
			#print eval( 'self.%s' % i )
			stateobj['state'][i] = eval( 'self.%s' % i )

		return stateobj

	def decodeTask(self,stateobj):
		data = stateobj['state']
		#print self
		#print dir(self)
		#print locals()['self']
		for i in data.keys():
			line = 'self.%s = data["%s"]' % (i,i)
			#print line
			exec line
			

	@property
	def bcast(self):
		return self._bcast
		
	@bcast.setter
	def bcast(self,value):
		self._bcast = value

	@property
	def owner(self):
		return self._owner

	@owner.setter
	def owner(self,value):
		self._owner = value
	
	@property
	def destination(self):
		return self._destination
	
	@destination.setter	
	def destination(self,value):
		self._destination = value
		
	@property
	def sender(self):
		return self._sender

	@sender.setter	
	def sender(self,value):
		self._sender = value

	@property
	def task(self):
		return self._task

	@task.setter
	def task(self,value):
		self._task = value
	
	@property
	def hostname(self):
		return self._hostname
		
	@hostname.setter
	def hostname(self,value):
		self._hostname = value
	
	@property
	def worker(self):
		return self._worker
	
	@worker.setter
	def worker(self,value):
		self._worker = value
