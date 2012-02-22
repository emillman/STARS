from task import Task, NEW, SUCCESS, ERROR
from os import system

from util import *

class OmnetTask(Task):


	# omnet config run number
	_run = None
	# name of custom config.ini file
	_ini = None
	# name of omnet config to run, defined in omnetpp.ini or config.ini
	_config_name = None

	# initialize the task object
	def __init__(self,*args,**kwargs):

		# these values are part of the task state
		self._statemembers = ['_run','_ini', '_config_name']

		Task.__init__(self, *args, **kwargs )

		if len(args) == 4:	
			self.display( OUTPUT_DEBUG, 'calling initializer for OmnetTask' )
			self._initOmnetTask( args[3] )


	def _initOmnetTask(self, run):

		self._run = run

		if 'process' in self._config:
			if 'config' in self._config['process']:
				self._config_name = self._config['process']['config']
			

		if 'OmnetTask' in self._config:
			if 'slots' in self._config['OmnetTask']:
				self.slots = int( self._config['OmnetTask']['slots'] )

		self._id = "sim_c%s_r%d" % ( self._config_name, self._run )
		self.addResult( '%s/sim' % self._config_name, '', 'rout-%s-%d.log' % (self._config_name, self._run ) )

	def createIni(self):
		if not self._config == None:
			
			name = 'Config %s' % self._config_name
			if name in self._config:
				self._ini = '%s_r%d.ini' % (self._config_name, self._run )
				f = open( '%s/model/%s' % ( self._root, self._ini ), 'w' )
				#f.write( 'include manet.ini\r\n' )

				idx = 0
				while idx in self._config[name]:
					line = self._config[name][idx]
					idx = idx + 1
					if line.lower().startswith('include'):
						f.write('%s\r\n' % line )

				f.write( '[%s]\r\n' % name )
				f.write( 'repeat=%s\r\n' % self._config['process']['repeat'] )
				f.write( 'sim-time-limit=%s s\r\n' % self._config['process']['tmax'] )
				f.write( '*.logger.**.path="%s/${configname}/sim/r${runnumber}/"\r\n' % self._config['general']['results'] )
				f.write( '*.logger.**.compress=%s\r\n' % self._config['process']['compress'] )
		
				idx = 0
				while idx in self._config[name]:
					line = self._config[name][idx]
					idx = idx + 1
					if line.lower().startswith('repeat'):
						continue
					elif line.lower().startswith('sim-time-limit'):
						continue
					elif line.lower().startswith('include'):
						continue
					f.write( '%s\r\n' % line )
					

				f.close()

				self.display(OUTPUT_DEBUG, 'creating %s file for simulation' % self._ini )
			else:
				self._ini = '%s.ini' % self._config_name

	def execute(self):
		path = self._root
		name = None
		cmdline = './omnet_run %s %d' % (self._config_name, self._run)

		self.createIni()
		if not self._ini == None:
			self.display( OUTPUT_DEBUG, 'set use of custom ini file %s' % self._ini )
			cmdline = '%s %s' % ( cmdline, self._ini )

		self.display( OUTPUT_DEBUG, cmdline )
			

		self.display( OUTPUT_MINOR, 'started: simulation %s run %d' % ( self._config_name, self._run ) )
			
		rcode = self.subprocess( cmdline + ' &> rout-%s-%d.log' % ( self._config_name, self._run ), path )
			
		self._result = []

		name_output = 'rout-%s-%d.log' % (self._config_name, self._run)

		if rcode == 0:
			self.state = SUCCESS
			self.addResult( '%s/sim' % self._config_name, self._root, name_output )
		#	path = '%s/results' % path
		#	name = '*_%s_r%d.tar.gz' % (self._config_name, self._run)
		#	self.addResult( '%s/sim' % self._config_name, path, name )
			
		else:
			self.state = ERROR
			self.addResult( '%s/err' % self._config_name, self._root + '/model', self._ini )
			self.addResult( '%s/err' % self._config_name, self._root, name_output )
		#else:
		#	self.addResult( '%s/sim' % self._config_name, self._root, name_output )
		
		


	def getRun(self):
		return self._run

	def getConfig(self):
		return self._config_name
