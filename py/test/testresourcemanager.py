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

from processmanager import ProcessManager
from resourcemanager import ResourceManager

from traceback import print_tb
from sys import exc_info

pm = ProcessManager( None )
rm = None

class FRMK:
	q = []
	workers = {0:{ 'name': 'localhost', 'mslots': 2, 'slots': 2, 'proc': [], 'reserved':False }}
	def queue_first(self,task):
		print 'worker performing process %d task' %( task.pid )
		rm.returnTask( task )
		
	def queue_task(self,task):
		print 'worker performing process %d task' %( task.pid )
		rm.returnTask( task )

frmk = FRMK()

proc_conf = { 'general':{ 'modulename':'TestProcess' }, 'process':{'maxtasks':3} }
error_conf = { 'general':{ 'modulename':'ErrorTestProcess'} };



try:
	rm = ResourceManager( None, None )
	print 'successfully created manager without framework or process manager'
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed creating resource manager without framework or process manager"

try:
	rm = ResourceManager( None, pm )
	print "successfully created manager without framework"
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed creating resource manager without framework"

try:
	rm = ResourceManager( None, pm )
	pm.newProc( proc_conf )
	pm.newProc( error_conf )
	
	task = True

	while not task == None:
		task = rm._nextTask()
		rm.returnTask( task )
		rm._cleanupProcs()

	print "got all tasks from process manager"

except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed running all tasks for a running process"	
	

try:
	rm = ResourceManager( frmk, pm )
	pm.newProc( proc_conf )

	task = True

	while not task == None:
		task = rm._nextTask()
		if not task == None:
			wid = rm._selectWorker( task )
			print 'task was assigned worker %d' % wid
		rm.returnTask( task )
		rm._cleanupProcs()

	print "got all tasks from process manager"
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed assigning tasks to every worker"	


try:
	rm = ResourceManager( frmk, pm )
	pm.newProc( proc_conf )

	task = True
	
	while rm.ready():
		rm.step()

	print "got all tasks from process manager"
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed assigning tasks to every worker"	
