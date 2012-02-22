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

from sys import path
from os import mkdir, getcwd, chdir, listdir, environ, system, remove
from shutil import move, rmtree
from tarfile import TarFile
from os.path import dirname, split
from time import time, asctime
from task import Task, NEW, SUCCESS, ERROR, WAIT

from dataaccess import DataAccess

from controltask import ControlTask
from process import PROC_READY, PROC_WAIT, PROC_ERROR, PROC_DONE, PROC_STOP

from util import *



MAX_PROC = 100

class ProcessManager(object):

	_procs = None
	_tracking = None
	_modulepath = None
	_newkey = None
	_done = False
	_nextpid = None
	_hostname = None

	_data_access = None

	def __init__(self,config):

		self._procs = {}
		self._tracking = {}
		self._newkey = 0
		self._done = False
		self._nextpid = 0
		self._hostname = 'localhost'

		self._modulepath = "%s/proc/" % environ['STARSPATH']

		self._data_access = DataAccess( environ['STARSPATH'] + '/stars.config' )

		if not config == None:
			if 'root_path' in config:
				self._modulepath = '%s/proc/' % config['root_path']
			if 'hostname' in config:
				self._hostname = config['hostname']
			

		self.display( OUTPUT_VERBOSE, 'initialized with modulepath of %s' % (self._modulepath) )

	def done(self):
		return self._done and len(self._procs) == 0

	def newProc(self,config):
		self.display( OUTPUT_VERBOSE, 'attemping to create new process' )
		result = None

		if 'general' in config:

			pid = self._nextpid

			while pid in self._procs:
				pid = pid + 1
				if not pid in self._procs:
					break

			self._nextpid = pid + 1

			self.display( OUTPUT_VERBOSE, 'found free pid of %d' % pid )

			proc = self._createProc(pid,config)

			if not proc == None:

				try:

					self.display( OUTPUT_MINOR, 'starting process %d' % ( pid ) )

					self._procs[pid] = proc
					self._tracking[pid] = { 'out':{}, 'ref':{}, 'started':time(), 'config':config,'issued':0, 'priority':0, 'workers':0, 'state':proc.state, 'notask':False, 'name':'' }
					if 'workers' in config['general']:
						self.setWorkers( pid, config['general']['workers'] )
	
					if 'priority' in config['general']:
						self.setPriority( pid, config['general']['priority'] )
					
					self._tracking[pid]['name'] = config['general']['modulename']

		                	if 'name' in config['general']:
                                        	self._tracking[pid]['name'] = config['general']['name']

					result = pid
				except:
					displayExcept()
					self.delProc( pid )
					pid = None

		return result

	def delProc(self,pid):

		result = None

		if pid in self._tracking:
			cwd = getcwd()
			chdir( self._modulepath )
			rmtree( str(pid), ignore_errors = True )
			chdir( cwd )
			self.display( OUTPUT_LOGIC, 'process %d modules deleted' % pid )
			result = pid
			del self._tracking[pid]

		if pid in self._procs:
			result = pid
			del self._procs[pid]
			

		if result == pid:
			self.display( OUTPUT_MINOR, 'process %d deleted' % result )

		return result
		
	def _createProc(self,pid,config):
		proc = None
		procpath = None
		cwd = getcwd()
		load = True
		try:
			if 'resources' in config['general'] and 'modulepath' in config['general']:

				self.display( OUTPUT_LOGIC, 'setting up python modules for process %d from: %s::%s' % ( pid, config['general']['resources'], config['general']['modulepath'] ) )

				#self.display('setting up process modules')
				cwd = getcwd()	
				chdir( self._modulepath )		
				self.display( OUTPUT_DEBUG, 'set current working directory to %s' % getcwd() )
				rmtree( str(pid), ignore_errors=True )
				mkdir( str(pid) )
				chdir( str(pid) )
				self.display( OUTPUT_DEBUG, 'set current working directory to %s' % getcwd() )
				
				temp = config['general']['resources'].split(':')
				srcHost = None
				srcPath = None
				fileName = None
				if len( temp ) == 1:

					srcPath = dirname(temp[0])
					fileName = split(temp[0])[1]

				elif len( temp ) == 2:
					srcHost = temp[0]
					srcPath = dirname(temp[1])
					fileName = split(temp[1])[1]

				if self._data_access.collect( getcwd(), fileName, srcHost, srcPath, fileName ):

					fname = split( config['general']['resources'] )[1]

					self.display( OUTPUT_DEBUG, 'trying to decompress %s' % fname )

					#self.display( OUTPUT_DEBUG, 'files in process directory' )
					#system( 'ls -al' )

					if 0 == system( 'tar zxf %s' % fname ):

						#self.display( OUTPUT_DEBUG, 'files in process directory' )
						#system( 'ls -al' )

						config['general']['localresources'] = '%s/%s' % ( getcwd(), split( config['general']['resources'] )[1] )

						files = listdir( config['general']['modulepath'] )

						if path.count( getcwd() ) == 0:
							procpath = getcwd() + '/' + config['general']['modulepath']
							path.insert( 0, procpath )
							self.display( OUTPUT_DEBUG, 'updated module path to include %s' % procpath )

						#for f in files:
						#	if f.endswith( '.py' ):
						#		move( config['general']['modulepath'] + '/' + f, './' )
						#		self.display( OUTPUT_DEBUG, 'moved %s into process cache' % f )
						
						#self.display( OUTPUT_DEBUG, 'files in process directory' )
						#system( 'ls -al' )

						# reload the module so we have the latest copy
						for f in files:
							if f.endswith( '.py' ):
								#print path
								#print getcwd()
								#print f.split('.')[0]
								module = __import__( f.split('.')[0] )
								reload( module )
								self.display( OUTPUT_DEBUG, 'loaded module %s' % f.split('.')[0] )

						#rmtree( dirname(config['general']['modulepath']), ignore_errors = True )

						#self.display( OUTPUT_DEBUG, 'files in process directory' )
						#system( 'ls -al' )
						
					else:
						self.display( OUTPUT_ERROR, 'failed to extract resources' )
						chdir( self._modulepath )
						rmtree( str(pid), ignore_errors = True )
						load = False
				else:
					self.display( OUTPUT_ERROR, 'failed to setup resources' )
					chdir( self._modulepath )
					rmtree( str(pid), ignore_errors = True )
					load = False

			if load and 'modulename' in config['general']:

				self.display( OUTPUT_DEBUG, 'creating process %d as: %s' % ( pid, config['general']['modulename'] ) )

				module = __import__( config['general']['modulename'].lower() )
				reload(module)
				context = {'config':config}
				proc = eval( 'module.%s( context, pid )' % config['general']['modulename'] )
			else:
				self.display( OUTPUT_ERROR, 'failed to start process' )
				chdir( self._modulepath )
				rmtree( str(pid), ignore_errors = True )

		except:
			displayExcept()
			rmtree( str(pid), ignore_errors=True )
			chdir( cwd )
			proc = None
			self.display( OUTPUT_ERROR, 'failed to create process' )

		if not load and not procpath == None:
			if path.count( procpath ) > 0:
				display( OUTPUT_DEBUG, 'removing path from process' )
				path.remove( procpath )

		return proc

	def nextControlTask(self):
		ctask = None
		for pid in self._tracking:
			info = self._tracking[pid]
			if info['state'] == PROC_READY:
				self.display( OUTPUT_VERBOSE, 'process %d is running, checking for control task' % pid )
				ctask = self._procs[pid].nextControlTask()
				if not ctask == None:
					self.display( OUTPUT_LOGIC, 'process %d gave control task %s' % (pid,str(ctask)) )
					ctask.pid = pid
					break
		return ctask

	def nextTask(self,pid):
		task = None
		if pid in self._tracking:
			info = self._tracking[pid]
			if info['state'] == PROC_READY:
				self.display( OUTPUT_VERBOSE, 'process %d is running, asking for task' % pid )
				task = self._task( pid )

		return task

	def firstDoneProc(self):
		result = None
		for pid in self._tracking.keys():
			info = self._tracking[pid]
			if info['state'] == PROC_DONE:
				self.display( OUTPUT_VERBOSE, 'process %d is the first done' % pid )
				result = pid
				break

		return result

	def nextProc(self):
		self.display( OUTPUT_VERBOSE, 'selecting next process' )
		result = None
		try:
			maxP = -1
			maxW = -1
			minS = -1

			for pid in self._tracking.keys():
				info = self._tracking[pid]
				
				self._procs[pid].determineState()

				if self._procs[pid].state == PROC_DONE:
					self.stopProc( pid )
					info = self._tracking[pid]

				if not self._procs[pid].state == PROC_READY:
					continue

				if info['notask']:
					info['notask'] = False
					continue

				if info['state'] == PROC_READY:
			
					pri = info['priority']
					wai = info['workers'] - len(info['out'])
					ser = info['issued']
					
					#print 'p%d - pri %d (%d) wai %d (%d) ser %d (%d)' % ( pid, pri, maxP, wai, maxW, ser, minS )

					# seed the search
					if minS == -1:
						#print 'a'
						self.display( OUTPUT_VERBOSE, 'chose pid %d as default.' % pid )

						maxP = pri
						maxW = wai
						minS = ser
						result = pid

					# higher priority and ( needs to fill quota or turn in line )
					elif pri > maxP and ( wai > 0 or wai >= maxW ):

						self.display( OUTPUT_VERBOSE, 'chose pid %d because it has higher priority and gets next worker' % pid )

						maxP = pri
						maxW = wai
						minS = ser
						result = pid

					# equal priority needing more resources
					elif pri == maxP and wai > maxW:

						self.display( OUTPUT_VERBOSE, 'chose pid %d because it needs more workers' % pid )

						maxP = pri
						maxW = wai
						minS = ser
						result = pid

					# equal standing, pick the one least chosen
					elif pri == maxP and wai == maxW and ser < minS:

						self.display( OUTPUT_VERBOSE, 'chose pid %d because it is under-serviced' % pid )

						maxP = pri
						maxW = wai
						minS = ser
						result = pid

				elif info['state'] == PROC_STOP:
					self.endProc( pid )

		except:
			displayExcept()
			result = None

		if not result == None:
			self.display( OUTPUT_DEBUG, 'process %d is the next in line' % result )

		return result

	def _task(self,pid):

		task = None

		if pid in self._procs:
			info = self._tracking[pid]
			try:
				task = self._procs[pid].task()
				if isinstance( task, Task ):
					task.pid = pid
					task.key = self._newkey
					self._newkey = self._newkey + 1
			
					if task.key in info['out'] or task.key in info['ref'] :
						self.display( OUTPUT_ERROR, 'non-unique task key! %s' % str(task.key) )

					info['out'][ task.key ] = time()
					info['ref'][ task.key ] = task
					info['issued'] = info['issued'] + 1

					if task.recover():
						if task.state == SUCCESS or task.state == ERROR:
							self.returnTask( task )
							task = None

				elif not task == None:
					self.endProc(pid)
			except:
				displayExcept()
				self.display( OUTPUT_ERROR, 'encountered error getting task from process %d' % pid )
				info['state'] = PROC_ERROR
				if not task == None:
					self.returnTask( task )
				self.endProc( pid )

			if task == None:
				info['notask'] = True

		else:

			self.display( OUTPUT_ERROR, 'requested task for unknown process %d' % pid )

		return task

	def peekTask(self,pid):
	
		task = None

		if pid in self._procs:

			task = self._procs[pid].peek()

		else:

			self.display( OUTPUT_ERROR, 'requested peek for unknown process %d' % pid )

		return task

	def getProcConfig(self,pid):
		result = None
		if pid in self._tracking:
			result = self._tracking[pid]['config']

		return result

	def endProc(self,pid):
		self.display( OUTPUT_VERBOSE, 'checking if process %d is done.' % pid )
		if pid in self._tracking:
			info = self._tracking[pid]
			if len(info['out']) == 0 and info['state'] == PROC_ERROR:
				self.display( OUTPUT_LOGIC, 'process %d had error and is ready to shutdown' % pid )
				info['state'] = PROC_STOP

			if len(info['out']) == 0 and info['state'] == PROC_STOP:
				self.display( OUTPUT_LOGIC, 'process %d is done.' % pid )
				info['state'] = PROC_DONE

	def stopProc(self,pid):
		if pid in self._tracking and self._tracking[pid]['state'] == PROC_READY:
			self.display( OUTPUT_MINOR, 'stopping process %d' % pid )
			self._tracking[pid]['state'] = PROC_STOP
			self.endProc( pid )

	def shutdown(self):
		self.display( OUTPUT_MAJOR, 'received shutdown request' )
		for pid in self._tracking.keys():
			self.stopProc( pid )
		self._done = True

	def setPriority(self,pid,priority):
		try:
			priority = int( priority )
			if pid in self._tracking:
				self.display( OUTPUT_MINOR, 'setting process %d to priority %d' % ( pid, priority ) )
				self._tracking[pid]['priority'] = priority
		except:
			self.display( OUTPUT_ERROR, 'invalid priority %s' % str(priority) )

	def setWorkers(self,pid,workers):
		try:
			workers = int(workers)
			if pid in self._tracking:
				self.display( OUTPUT_MINOR, 'setting process %d to workers %d' % ( pid, workers ) )
				self._tracking[pid]['workers'] = workers
		except:
			self.display( OUTPUT_ERROR, 'invalid workers %s' % str(workers) )


	def returnTask(self,task):

		if isinstance( task, Task ):
			self.display( OUTPUT_VERBOSE, 'received task' )
			
			if task.pid in self._tracking:
				self.display( OUTPUT_DEBUG, 'task is known' )
				info = self._tracking[task.pid]

				if task.key in info['out']:
					del info['out'][ task.key ]

				if task.key in info['ref']:
					del info['ref'][ task.key ]
	
			try:
				if not task.store():
					self.display( OUTPUT_ERROR, 'task %s for process %d failed to store results' % (task.id(),task.pid) )
					info['state'] = PROC_ERROR

				self.display( OUTPUT_LOGIC, 'gave process %d task %s' % (task.pid,task.id()) )
				self._procs[task.pid].handle( task )
			except:
				displayExcept()
				self.display( OUTPUT_ERROR, 'process %d encountered an error handling task %s' % (task.pid,task.id()) )
				info['state'] = PROC_ERROR

			self.endProc(task.pid)


				
	def display(self, level, text):
		display( level, 'Process Manager: %s' % text )
