from task import Task, NEW, SUCCESS, ERROR
from wg_task import WG_Task
from os import system

from util import *

class WG_QstatTask(WG_Task):

	__ids__ = None

	# initialize the task object
	def __init__(self,*args,**kwargs):

		# these values are part of the task state
		self._statemembers = ['__ids__']

		WG_Task.__init__(self, *args, **kwargs )

		if not 'stateobj' in kwargs:
			self.__ids__ = {}

	def execute(self):
		cmdline = '/global/system/torque/bin/qstat -u %s' % self.__user__
		outfile = 'wgout-%s.log' % self.id()
		if not 0 == self._sshSubProc( cmdline, outfile ):
			self.state = ERROR
		else:
			fid = open(outfile)
			lines = fid.readlines()
			fid.close()
			data = {}
			for line in lines:
				line = line.split()
				if len(line) == 11:
					job_id = line[0].split('.')[0]
					if job_id[0] == '-':
						continue
					queue = line[2]
					status = line[9]
					etime = line[10]
					data[job_id] = ( queue, status, etime )

			self.__ids__ = data

	def getIds(self):
		return self.__ids__

