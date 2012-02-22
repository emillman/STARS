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

# test code for process manager
from traceback import print_tb
from sys import exc_info
			
from processmanager import *

pm = None
proc_conf = { 'general':{ 'modulename':'TestProcess' }, 'process':{'maxtasks':3} }
error_conf = { 'general':{ 'modulename':'ErrorTestProcess'} };
proc = None
task = None

try:
	pm = ProcessManager(None)
	print pm._modulepath
	print "passed configless creation"
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed configless creation"

try:
	pid = pm.nextProc()
	if pid == None:
		print 'passed nextProc with no next process'
	else:
		print 'passed nextProc with no next process'
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'passed nextProc with no next process'

try:
	pid = pm.newProc( proc_conf )
	print pm._procs
	if not pid == None:
		print "passed process creation"
	else:
		print "failed process creation"
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed process creation"

try:
	pid = pm.nextProc()
	if not pid == None:
		print 'passed nextProc with next process'
	else:
		print 'failed nextProc with next process'
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed nextProc with next process'


try:
	pid = pm.delProc( 0 )
	if pid == 0:
		print "passed process removal"
	else:
		print "failed process removal"

except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print "failed process removal"

try:
	pid = pm.nextProc()
	if pid == None:
		print 'passed netTask with no available proc or task'
	else:
		task = pm.nextTask( pid )
		if task == None:
			print 'failed nextTask with no available proc or task'
		else:
			print 'failed nextTask with no available proc or task'
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed nextTask with no available proc or task'

try:
	pm.newProc( proc_conf )
	pid = pm.nextProc()
	task = pm.nextTask( pid )
	if not task == None:
		print task
		print 'passed nextTask with available proc and task'
	else:
		print 'failed nextTask with available proc and task'
	pm.returnTask( task )
	pm.delProc( pid )
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed nextTask with available proc and task'

try:
	pm.newProc( proc_conf )
	pid = True
	try:
		while not pid == None:
			pid = pm.nextProc()

			if not pid == None:
				task = pm.nextTask( pid )
				if task == None:
					print 'process does not have a task ready'
				else:
					pm.returnTask(task)
			
			else:
				print 'no process was available'

			while True:
				p = pm.firstDoneProc()
				if not p == None:
					pm.delProc( p )
					break
				else:
					break

	except:
		print exc_info()[0]
		print exc_info()[1]
		print_tb(exc_info()[2])
		print 'process encountered an error'
	
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed running process to completion'

try:
	pm.newProc( error_conf )
	pid = pm.nextProc()
	task = pm.nextTask( pid )
	if task == None:
		print 'successfully handled error getting task'
	else:
		print 'failed to handle error while getting task'

	pm.returnTask( task )

	while True:
		p = pm.firstDoneProc()
		if not p == None:
			pm.delProc( p )
			break
		else:
			break
except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed running process to error'


try:
	pid = pm.newProc( proc_conf )
	pm.stopProc( pid )

	while True:
		p = pm.firstDoneProc()
		if not p == None:
			pm.delProc( p )
			break
		else:
			break

except:
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])
	print 'failed to stopping process'
