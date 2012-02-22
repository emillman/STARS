from util import *
from process import Process, PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR
from westgridprocess import WestGridProcess




class WG_AnalysisProcess(WestGridProcess):

	def __init__(self,context,id):
		WestGridProcess.__init__(self,context,id)

		if 'config' in context:
			self.__config__ = context['config']
		else:
			raise Exception('WG_AnalysisProcess','no config found in context.')
		
		if 'process' in self.__config__:

			if 'interval' in self.__config__['process']:
				self.__interval__ = self.__config__['process']['interval']
			else:
				self.__interval__ = 300
		else:
			raise Exception('WG_AnalysisProcess','no process section found in workfile')

		self.display( OUTPUT_MAJOR, 'Process Running for %s@%s using interval of %0.3f minutes' % ( self.__user__, self.__host__, self.__interval__/60.0) )
	
	def step(self):
		return None

	def _handleJobDone(self, job):
		print job
		print self.__jobs__[job]

	def _handleSuccess(self, task):
		pass

	def _handleError(self, task):
		self.state = PROC_ERROR
		
