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
from task import Task, NEW, SUCCESS

from util import *

class ShutdownTask(ControlTask):
	

	def __init__(self,*args,**kwargs):

		ControlTask.__init__(self, *args, **kwargs )
	
		if len(args) >= 3:
			self._initShutdownTask()

	def _initShutdownTask(self):
		self.bcast = True


	def finish(self):
		if self.sender in self.node.workers:
			self.display( OUTPUT_DEBUG, 'removing worker %d' % self.sender )
			del self.node.workers[ self.sender ]
							
		if len( self.node.workers ) == 0:
			self.display( OUTPUT_MAJOR, 'all workers down, shutting down system' )
			self.node._done = True
			return True

		return False

	def execute(self):

		if self.node._inuse == 0 and len( self.node._msgq ) == 0:

			self.node._done = True
			self.display( OUTPUT_DEBUG, 'shutting down' )
			self.state = SUCCESS

		else:
			self.node.queue( self )
