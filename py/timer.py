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

from task import Task
from time import time
from os import system

class Timer:

	_timers = None
	_times = None
	_name = None

	def __init__(self, name):
		self._timers = {}
		self._times = []
		self._name = name
		cmdline = 'stat log/tout-%s.log &> /dev/null' % name
		if 0 == system( cmdline ):
			cmdline = 'rm -rf log/tout-%s.log > /dev/null' % name
			system( cmdline )

	def start(self,key):
		if not key == None:
			self._timers[key] = time()

	def stop(self,key):
		if key in self._timers:
			t = time() - self._timers[key]
			del self._timers[key]
			self._times.append( t )

	def record(self):
		f = open( 'log/tout-%s.log' % self._name, 'a' )
		while len( self._times ) > 0:
			t = self._times.pop(0)
			f.write('%f\r\n' % t )
		f.close()
