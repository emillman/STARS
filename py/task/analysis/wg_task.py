from task import Task, NEW, SUCCESS, ERROR
from os import system, environ

from util import *

class WG_Task(Task):

	__user__ = None
	__key__ = None
	__host__ = None

	# initialize the task object
	def __init__(self,*args,**kwargs):

		# these values are part of the task state
		self._statemembers = ['__user__','__key__','__host__']

		Task.__init__(self, *args, **kwargs )

		if not 'stateobj' in kwargs:
			self._initWG_Task()


	def _initWG_Task(self):
		if 'process' in self._config:
			if 'host' in self._config['process']:
				self.__host__ = self._config['process']['host']
			else:
				raise Exception('WG_Task','required field [process]:host not found in workfile')

			if 'user' in self._config['process']:
				self.__user__ = self._config['process']['user']
			else:
				self.__user__ = environ['USER']

			if 'key' in self._config['process']:
				self.__key__ = self._config['process']['key']
			else:
				if 0 == system( 'stat ~/.ssh/id_rsa &> /dev/null' ):
					self.__key__ = '~/.ssh/id_rsa'
				else:
					raise Exception('WG_Task','required field [process]:key="~/.ssh/id_rsa" not found in workfile')
		else:
			raise Exception('WG_Task','no process section found in workfile')
		
	def _sshSubProc(self,cmdline, outfile):
		ssh_o = '-i %s -o StrictHostKeyChecking=no' % self.__key__
		cmdline = 'ssh %s@%s %s "%s"' % ( self.__user__, self.__host__, ssh_o, cmdline )
		if not outfile == None:
			cmdline = '%s &> %s' % ( cmdline, outfile )
		else:
			cmdline = '%s &> wgout-%s.log' % ( cmdline, self.id() )
		return system( cmdline )
