from task import Task, NEW, SUCCESS, ERROR
from wg_task import WG_Task
from os import system

from util import *

class WG_QdelTask(WG_Task):

	__job_id__ = None

	# initialize the task object
	def __init__(self,*args,**kwargs):

		# these values are part of the task state
		self._statemembers = ['__job_id__']

		WG_Task.__init__(self, *args, **kwargs )


	def execute(self):
		cmdline = '/global/system/torque/bin/qdel %s' % self.__job_id__

		if not 0 == self._sshSubProc( cmdline ):
			self.state = ERROR
