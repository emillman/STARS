from task import Task, NEW, SUCCESS, ERROR
from wg_task import WG_Task
from os import system, stat
from os.path import split, exists, dirname
from util import *

class WG_DeployTask(WG_Task):

	# initialize the task object
	def __init__(self,*args,**kwargs):

		# these values are part of the task state
		self._statemembers = []

		WG_Task.__init__(self, *args, **kwargs )

	def execute(self):
		if 'general' in self._config:
			if 'results' in self._config['general']:
				temp = self._config['general']['results'].split(':')
				if len( temp ) == 1:
					self._data_access.setStore( self.__host__, temp[0], False )
				elif len( temp ) == 2:
					self._data_access.setStore( self.__host__, temp[1], False )

		if 'localresources' in self._config['general']:
			fi = stat( self._config['general']['localresources'] )
			self.display( OUTPUT_MINOR, 'deploying process %d resources to westgrid (%0.3fMB)' % ( self.pid, fi.st_size/1024.0/1024.0 ) )

			filePath = dirname( self._config['general']['localresources'] )
			fileName = split( self._config['general']['localresources'] )[1]
			if not self._data_access.deploy( filePath, fileName, self.__host__, self._config['general']['results'], '%d.tar.gz' % self.pid ):
				raise Exception('WG_DeployTask','Could not deploy resources file to westgrid')
			else:
				cmdline = 'mkdir -p %s/%s' % ( self._config['general']['results'], self._config['process']['config'] )
				cmdline = '%s && cd %s/%s' % ( cmdline, self._config['general']['results'], self._config['process']['config'] )
				cmdline = '%s && tar zxf ../%d.tar.gz' % ( cmdline, self.pid )
				cmdline = 'ssh %s %s@%s "%s"' % ( self._data_access._ssh_o, self.__user__, self.__host__, cmdline )
				if not 0 == system( cmdline ):
					raise Exception('WG_DeployTask','could not decompress resources on westgrid')
		
			
