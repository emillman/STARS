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
from os import system

class Instrument:

	_timers = None
	_records = None
	_name = None
	_maxrecords = None

	def __init__(self, name, maxrecords):
		self._timers = {}
		self._records = []
		self._maxrecords = maxrecords
		self._name = name
		cmdline = 'stat log/iout-%s.log > /dev/null' % name
		if 0 == system( cmdline ):
			cmdline = 'rm -f log/iout-%s.log > /dev/null' % name
			system( cmdline )

	def start(self,key):
		if not key == None:
			self._timers[key] = time()

	def stop(self,key,records):
		if key in self._timers:
			t = time() - self._timers[key]
			del self._records[key]
			self._records.append( (t,records) )
			if len( self._records ) > self._maxrecords:
				self.record()

	def record(self):
		f = open( 'log/iout-%s.log' % self._name, 'a' )
		while len( self._records ) > 0:
			t = self._records.pop(0)
			f.write('%f\r\n' % t )
		f.close()
