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

from process import Process, PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR
from surfacetask import SurfaceTask
from matlabtask import MatlabTask
from omnettask import OmnetTask

from task import SUCCESS, ERROR

from util import *

class AnalysisProcess(Process):

	__first_repeat__ = None
	__repeat__ = None
	__max_repeat__ = None
	__parameter__ = None
	__surface__ = None

	__max_more__ = None
	
	__config__ = None
	
	def __init__(self,context, id, parameter):
		Process.__init__(self,context, id)
		
		if 'parameter' in context:
			self.__parameter__ = context['parameter']
		
		if 'config' in context:
			self.__config__ = context['config']
			#display( OUTPUT_DEBUG, str(self.__config__) )
		else:
			raise Exception('AnalysisProcess','no config found in context.')

		self.__max_more__ = 0
		start_repeat = 0
		self.__surface__ = False
		if 'process' in self.__config__:
			if 'repeat' in self.__config__['process']:
				self.__max_repeat__ = int(self.__config__['process']['repeat'])
			else:
				raise Exception('AnalysisProcess','no repeats field found in process section of workfile')

			if 'start_repeat' in self.__config__['process']:
				start_repeat = int(self.__config__['process']['start_repeat'])

			if 'max_more' in self.__config__['process']:
				self.__max_more__ = int(self.__config__['process']['max_more'])

			if 'surface' in self.__config__['process']:
				self.__surface__ = True
		else:
			raise Exception('AnalysisProcess','no process section found in workfile')
		
		self.__parameter__ = parameter
		self.__first_repeat__ = 0
		self.__repeat__ = 0
		if not self.__max_more__ > 0:
			self.__max_more__ = self.__max_repeat__

		self.display( OUTPUT_MAJOR, '%s initialized for parameter %d with maximum %d repeats' % (self.__config__['process']['config'], self.__parameter__, self.__max_repeat__) )

		if start_repeat > 0:
			self.__queueSimulations__( start_repeat )
		else:
			self.__queueAnalysis__()
		
	def __queueSimulations__(self,repeats):
		for run in range(0,repeats):
			if len(self.tasks) + self.__repeat__ < self.__max_repeat__:
				offset = self.__repeat__ + (self.__parameter__-1)*self.__max_repeat__
				from omnettask import OmnetTask
				task = OmnetTask( self.id(), run + offset, self.__config__, run + offset  )
				self.tasks.append( task )

		self.determineState()
				
		self.__first_repeat__ = self.__repeat__
		self.__repeat__ = self.__repeat__ + repeats
		if self.__repeat__ > self.__max_repeat__:
			self.__repeat__ = self.__max_repeat__
				
	def __queueAnalysis__(self):
		from matlabtask import MatlabTask
		task = MatlabTask( self.id(), self.__parameter__, self.__config__, self.__parameter__, self.__repeat__, self.__first_repeat__ )

		self.tasks.append( task )

		if self.__surface__ and self.__repeat__ == self.__max_repeat__:
			self.__queueSurface__()

		self.determineState()

	def __queueSurface__(self):
		from surfacetask import SurfaceTask
		task = SurfaceTask( self.id(), None, self.__config__, self.__parameter__, self.__repeat__)
		self.__surface__ = False
		self.tasks.append( task )
		
		self.determineState()
	
	def _handleSuccess(self,task):
		from omnettask import OmnetTask
		from matlabtask import MatlabTask
		from surfacetask import SurfaceTask
		
		if isinstance( task, OmnetTask ):

			self.display( OUTPUT_MINOR, 'simulation run %d completed for parameter %d' % ( task.getRun(), self.__parameter__ ) )
			if len( self.tasks ) + len( self.out ) == 0:
				self.__queueAnalysis__()

		elif isinstance( task, MatlabTask ):
			more_runs = task.moreRuns()
			if more_runs > 0:
				if self.__repeat__ >= self.__max_repeat__:
					self.display( OUTPUT_MAJOR, 'failed to meet analysis requirements for parameter %d' % self.__parameter__ )
					self.state = PROC_ERROR
				else:
					self.display( OUTPUT_MAJOR, 'need %d more simulation repetitions for parameter %d' % (more_runs,self.__parameter__) )
					if more_runs < self.__max_more__:
						self.__queueSimulations__( more_runs )
					else:
						self.__queueSimulations__( self.__max_more__ )
			else:
				self.display( OUTPUT_MAJOR, 'parameter %d finished' % self.__parameter__ )
				if self.__surface__:
					self.__queueSurface__()
				else:
					self.determineState()

		elif isinstance( task, SurfaceTask ):
			self.display( OUTPUT_MAJOR, 'surface %d finished' % self.__parameter__ )
			self.determineState()
		
		return
		
	def _handleError(self,task):
		self.state = PROC_ERROR

		return
		
