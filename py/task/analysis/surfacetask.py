from task import Task, NEW, SUCCESS, ERROR
from os import system

from util import *

class SurfaceTask(Task):

	_par = None
	_repeat = None
	_config_name = None
	_config = None
	_script_name = None
	_script_file = None

	def __init__(self,*args,**kwargs):

		self._statemembers = [ '_par', '_repeat', '_config_name', '_script_name' ]

		Task.__init__(self, *args, **kwargs )

		if len(args) == 5:	
			self.display( OUTPUT_DEBUG, 'calling initializer for SurfaceTask' )
			self._initSurfaceTask( args[3], args[4] )


	def _initSurfaceTask(self, par, repeat ):

		if 'process' in self._config:
			if 'config' in self._config['process']:
				self._config_name = self._config['process']['config']
			else:
				raise Exception('SurfaceTask','no config value set under process section of workfile.')
			if 'script' in self._config['process']:
				self._script_name = self._config['process']['script']
			else:
				raise Exception('SurfaceTask','no script value set under process section of workfile.')
		else:
			raise Exception('SurfaceTask','no process section in workfile.')

		if 'SurfaceTask' in self._config:
			if 'slots' in self._config['SurfaceTask']:
				self.slots = int( self._config['SurfaceTask']['slots'] )

		self._par = par
		self._repeat = repeat

		self._script_file = None

		self._id = "sur_c%s_s%d" % ( self._config_name, par )
		self.addResult( '%s/sur' % self._config_name, '', 'sout-%s-%d.log' % ( self._config_name, par) )

		self.display( OUTPUT_DEBUG, 'finished initializer for SurfaceTask' )

	def createScript(self):
		if not self._config == None:
			
			name = 'Script %s' % self._script_name
			if name in self._config:
				self._script_file = '%s_%d.m' % (self._script_name, self._par )
				self._script_name = '%s_%d' % (self._script_name, self._par)
				f = open( '%s/%s' % ( self._root, self._script_file ), 'w' )

				f.write( "config='%s';\r\n" % ( self._config_name ) )
				f.write( "store='%s';\r\n" % ( self._config['general']['results'] ) )
				f.write( 'repeat=%d;\r\n' % ( self._repeat ) )
				f.write( 'max_repeat=%s;\r\n' % ( self._config['process']['repeat'] ) )
				f.write( 'tmax=%s;\r\n' % ( self._config['process']['tmax'] ) )
				f.write( 'parameter=%d;\r\n' % ( self._par ) )

				idx = 0
				while idx in self._config[name]:
					line = self._config[name][idx]
					idx = idx + 1
					if line.lower().startswith('config'):
						continue
					elif line.lower().startswith('store'):
						continue
					elif line.lower().startswith('repeat'):
						continue
					elif line.lower().startswith('max_repeat'):
						continue
					elif line.lower().startswith('tmax'):
						continue
					elif line.lower().startswith('parameter'):
						continue

					f.write( '%s\r\n' % line )

				f.close()

				self.display(OUTPUT_DEBUG, 'creating %s file for analysis' % self._script_file )

	def execute(self):
		path = self._root

		self.createScript()
		if not self._script_file == None:
			self.display( OUTPUT_DEBUG, 'set use of custom script file %s' % self._script_file )


		self.display( OUTPUT_DEBUG, "performing analysis of %s parameter %d" % ( self._config_name, self._par ) )
		if self._par > 0:
			cmdline = './matlab_run surfaceParameter %s' % (self._script_name )
		else:
			cmdline = 'exit 1'
		rcode = self.subprocess( cmdline + ' &> sout-%s-%d.log' % ( self._config_name, self._par ), path )
		
		name = None
		self._result = []


		name_output = 'sout-%s-%d.log' % ( self._config_name, self._par )

		if rcode == 0:
			self.state = SUCCESS
			if self._par > 0 and 0 == system( 'stat %s/cache/%s_s%d.mat &> /dev/null' % ( path, self._config_name, self._par ) ):
				path = '%s/cache' % path
				name = '%s_s%d.mat' % ( self._config_name, self._par )
				self.addResult( '%s/sur' % self._config_name, path, name )

			else:
				self.state = ERROR
		else:
			self.state = ERROR
			
		if self.state == ERROR:
			name = '%s.m' % self._script_name
			self.addResult( '%s/err' % self._config_name, self._root, name )
			self.addResult( '%s/err' % self._config_name, self._root, name_output )
		else:
			self.addResult( '%s/sur' % self._config_name, self._root, name_output )

	def getPar(self):
		return self._par

	def getConfig(self):
		return self._config_name
