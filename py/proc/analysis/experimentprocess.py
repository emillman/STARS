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

from util import *
from process import Process, PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR
from task import SUCCESS, ERROR
from analysisprocess import AnalysisProcess
from matlabtask import MatlabTask

class ExperimentProcess(Process):

	__first__ = None

	__config__ = None
	__repeat__ = None

	__parameters__ = None

	def __init__(self,context,id):
		Process.__init__(self,context,id)

		if 'config' in context:
			self.__config__ = context['config']
			#display( OUTPUT_DEBUG, str(self.__config__) )
		else:
			raise Exception('ExperimentProcess','no config found in context.')
		
		repeat = 0
		runs = 0
		if 'process' in self.__config__:
			if 'repeat' in self.__config__['process']:
				self.__repeat__ = int(self.__config__['process']['repeat'])
			else:
				raise Exception('ExperimentProcess','no repeats field found in process section of workfile')

			if 'runs' in self.__config__['process']:
				runs = int(self.__config__['process']['runs'])
			else:
				raise Exception('ExperimentProcess','no runs field found in process section of workfile')
		else:
			raise Exception('ExperimentProcess','no process section found in workfile')

		self.__first__ = False

		self.__parameters__ = int( runs / self.__repeat__ )

		self.display( OUTPUT_MAJOR, '%s initialized for %d parameters totalling %d runs' % (self.__config__['process']['config'], self.__parameters__, runs) )

		self.__queueAnalysis__()

	def __queueAnalysis__(self):
		for p in range(0,self.__parameters__):
			from analysisprocess import AnalysisProcess
			self.sub_procs.append( AnalysisProcess( self.context, self.id(), p+1 ) )
		self.determineState()

	def __queueExperiment__(self):
		from matlabtask import MatlabTask
		task = MatlabTask( self.id(), 0, self.__config__, 0, self.__repeat__, 0 )
		self.tasks.append( task )
		self.determineState()

	def _handleSuccess(self, task):
		self.state = PROC_DONE

		return

	def _handleError(self, task):
		#print task.state
		if self.__first__:
			self.__first__ = False
			task._result = []
			self.__queueAnalysis__()
		elif task.state == ERROR:
			self.state = PROC_ERROR

	def _subprocDone(self, p ):
		# self.__queueSurface__( p )
		pass

	def _subprocsDone(self):
		if not self.state == ERROR:
			self.__queueExperiment__()
		
