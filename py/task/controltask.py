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

from task import Task, SUCCESS

from util import *

class ControlTask(Task):
	
	_node = None

	def __init__(self,*args,**kwargs):

		if self._statemembers == None:
			self._statemembers = []

		#self._statemembers.append( 'node' )

		Task.__init__(self, *args, **kwargs )

		if len(args) >= 3:
			self.display( OUTPUT_DEBUG, 'calling initializer for ControlTask' )
			self._initControlTask( )


	def _initControlTask(self):
		self.slots = 0
		self.node = None
		self.display( OUTPUT_DEBUG, 'finished initializer for ControlTask' )

	@property
	def node(self):
		return self._node

	@node.setter
	def node(self,value):
		self._node = value

	def execute(self):
		return False
