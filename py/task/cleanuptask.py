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

from util import *

class CleanupTask(ControlTask):

	def __init__(self,*args,**kwargs):

		ControlTask.__init__(self, *args, **kwargs )
	
		if len(args) >= 3:
			self._initCleanupTask()

	def _initCleanupTask(self):
		self.bcast = True

	def execute(self):
		self.state = FAIL
		if system( 'stat %s/ &> /dev/null' % self._root ) == 0:

			rmtree( self._root + '/', ignore_errors=True )
			self.display( OUTPUT_LOGIC, 'process %d resources removed.' % self._owner )

		if self.owner in self.node._procs:
			del self.node._procs[ self.owner ]

		self.state = SUCCESS


	def finish(self):
		if self._bcast:
			if self.node.workers[ self.sender ]['proc'].count( self.owner ) > 0:
				self.node.workers[ self.sender ]['proc'].remove( self.owner )
						
			done = True
			for w in self.node.workers.keys():
				if self.node.workers[w]['proc'].count( self.owner ) > 0:
					done = False
					break

			return done
		return False
