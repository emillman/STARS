from util import *
from process import Process, PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR
from westgridprocess import WestGridProcess
from wg_qstattask import WG_QstatTask

class WestGridStatusProcess(WestGridProcess):

	def __init__(self,context,id):
		WestGridProcess.__init__(self,context,id)

		if 'config' in context:
			self.__config__ = context['config']
		else:
			raise Exception('WestGridStatusProcess','no config found in context.')
		
		if 'process' in self.__config__:

			if 'interval' in self.__config__['process']:
				self.__interval__ = self.__config__['process']['interval']
			else:
				self.__interval__ = 300
		else:
			raise Exception('WestGridStatusProcess','no process section found in workfile')

		self.display( OUTPUT_MAJOR, 'Status Process Running for %s@%s using interval of %0.3f minutes' % ( self.__user__, self.__host__, self.__interval__/60.0) )

	
	def step(self):
		return None

	def _handleSuccess(self, task):
		pass

	def _handleError(self, task):
		self.state = PROC_ERROR
		
