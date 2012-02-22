from os import environ, system
from time import time
from util import *
from process import Process, PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR
from wg_qstattask import WG_QstatTask
from wg_deploytask import WG_DeployTask

from dataaccess import DataAccess

class WestGridProcess(Process):

	__host__ = None
	__user__ = None
	__key__ = None
	__last_time__ = None
	__interval__ = None

	__jobs__ = None

	data_access = None

	def __init__(self,context,id):
		Process.__init__(self,context,id)

		if 'config' in context:
			self.__config__ = context['config']
		else:
			raise Exception('WestGridStatusProcess','no config found in context.')
		
		if 'process' in self.__config__:
			if 'host' in self.__config__['process']:
				self.__host__ = self.__config__['process']['host']
			else:
				raise Exception('WestGridProcess','required field [process]:host not found in workfile')

			if 'user' in self.__config__['process']:
				self.__user__ = self.__config__['process']['user']
			else:
				self.__user__ = environ['USER']

			if 'key' in self.__config__['process']:
				self.__key__ = self.__config__['process']['key']
			else:
				if 0 == system( 'touch ~/.ssh/id_rsa &> /dev/null' ):
					self.__key__ = '~/.ssh/id_rsa'
				else:
					raise Exception('WestGridProcess','required field [process]:key="~/.ssh/id_rsa" not found in workfile')
		else:
			raise Exception('WestGridProcess','no process section found in workfile')

		self.__last_time__ = 0
		self.__jobs__ = {}
		
		task = WG_DeployTask( self.id(), None, self.__config__ )
		task.execute()

	def step(self):
		raise Exception('WestGridProcess','must implement step method')	

	def getTask(self):
		self.__last_time__ = time()

		if len( self.__jobs__ ) > 0:

			task = WG_QstatTask( self.id(), None, self.__config__ )
			task.execute()
			found = task.getIds()
			print found
			for job in self.__jobs__:
				if not job in found:
					self._handleJobDone( job )
			for job in found:
				self.__jobs__[job] = found[job]
				

		return self.step()

	def determineState(self):
		if self.__interval__ == None or time() - self.__last_time__ > self.__interval__:
			self.state = PROC_READY
		else:
			self.state = PROC_WAIT

	def _handleJobDone(self, job):
		raise Exception('WestGridProcess','user must implement _handleJobDone method')

	def _subprocDone(self, p ):
		pass

	def _subprocsDone(self):
		pass
		
