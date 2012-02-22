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

from task import Task, NEW, SUCCESS, ERROR
from time import time
from subprocess import Popen, PIPE
from controltask import ControlTask


class StatusTask(ControlTask):

	def __init__(self,*args,**kwargs):

		ControlTask.__init__(self, *args, **kwargs )
	
		if len(args) >= 3:
			self._initStatusTask()

	def _initStatusTask(self):
		pass

	def execute(self):
		#print 'checking worker status'
		p = Popen( 'uptime', shell=True, stdout=PIPE )
		text = p.communicate()[0]
		text = text.split()
		text = text[-3:]
		
		data = {}
		
		data['load'] = {1:float( text[0].strip(',')), 5:float( text[1].strip(',')), 15:float( text[2].strip(',') ) }

		p = Popen( 'free -o', shell=True, stdout=PIPE )
		text = p.communicate()[0]
		
		text = text.split('\n')
		text1 = text[1].split()
		text2 = text[2].split()
		
		data['memory'] = { 'phys':(float( text1[3] ) /  float( text1[1] )), 'swap':(float( text2[3] ) /  float( text2[1] )) }

		self._result = data

		self.state = SUCCESS

			

