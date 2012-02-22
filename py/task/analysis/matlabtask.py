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

from task import Task, NEW, SUCCESS, ERROR

from os import system

from util import *

class MatlabTask(Task):

	_more_runs = None
	_par = None
	_repeat = None
	_first_repeat = None
	_config_name = None
	_config = None
	_script_name = None
	_script_file = None

	def __init__(self,*args,**kwargs):

		self._statemembers = [ '_par', '_repeat', '_first_repeat', '_config_name', '_script_name', '_more_runs' ]

		Task.__init__(self, *args, **kwargs )

		if len(args) == 6:	
			self.display( OUTPUT_DEBUG, 'calling initializer for MatlabTask' )
			self._initMatlabTask( args[3], args[4], args[5] )


	def _initMatlabTask(self, par, repeat, first_repeat ):

		if 'process' in self._config:
			if 'config' in self._config['process']:
				self._config_name = self._config['process']['config']
			else:
				raise Exception('MatlabTask','no config value set under process section of workfile.')
			if 'script' in self._config['process']:
				self._script_name = self._config['process']['script']
			else:
				raise Exception('MatlabTask','no script value set under process section of workfile.')
		else:
			raise Exception('MatlabTask','no process section in workfile.')

		if 'MatlabTask' in self._config:
			if 'slots' in self._config['MatlabTask']:
				self.slots = int( self._config['MatlabTask']['slots'] )

		self._par = par
		self._repeat = repeat
		self._first_repeat = first_repeat

		self._script_file = None

		self._id = "ana_c%s_p%d" % ( self._config_name, par )
		self.addResult( '%s/ana' % self._config_name, '', 'aout-%s-%d.log' % ( self._config_name, par) )

		self.display( OUTPUT_DEBUG, 'finished initializer for MatlabTask' )

	def createScript(self):
		if not self._config == None:
			
			name = 'Script %s' % self._script_name
			if name in self._config:
				self._script_file = '%s_%d.m' % (self._script_name, self._par )
				self._script_name = '%s_%d' % (self._script_name, self._par)
				f = open( '%s/%s' % ( self._root, self._script_file ), 'w' )

				f.write( "context.config='%s';\r\n" % ( self._config_name ) )
				f.write( "context.store_path='%s';\r\n" % ( self._config['general']['results'] ) )
				f.write( 'context.repeat=%d;\r\n' % ( self._repeat ) )
				f.write( 'context.max_repeat=%s;\r\n' % ( self._config['process']['repeat'] ) )
				f.write( 'context.tmax=%s;\r\n' % ( self._config['process']['tmax'] ) )
				f.write( 'context.raw_compression=%s;\r\n' % self._config['process']['compress'] )
				f.write( 'context.parameter=%d;\r\n' % ( self._par ) )

				if self._first_repeat > 0:
					f.write( 'first_repeat=%d;\r\n' % ( self._first_repeat ) )

				idx = 0
				while idx in self._config[name]:
					line = self._config[name][idx]
					idx = idx + 1
					if line.lower().startswith('context.config'):
						continue
					elif line.lower().startswith('context.store_path'):
						continue
					elif line.lower().startswith('context.repeat'):
						continue
					elif line.lower().startswith('context.max_repeat'):
						continue
					elif line.lower().startswith('context.tmax'):
						continue
					elif line.lower().startswith('context.parameter') and not line.lower().startswith('context.parameters'):
						continue
					elif line.lower().startswith('context.raw_compression'):
						continue

					f.write( '%s\r\n' % line )

				f.close()

				self.display(OUTPUT_DEBUG, 'creating %s file for analysis' % self._script_file )

	def execute(self):
		path = self._root

		self.createScript()
		if not self._script_file == None:
			self.display( OUTPUT_DEBUG, 'set use of custom script file %s' % self._script_file )


		self.display( OUTPUT_VERBOSE, "performing analysis of %s parameter %d" % ( self._config_name, self._par ) )
		if self._par > 0:
			cmdline = './matlab_run analyzeParameter %s' % (self._script_name )
		else:
			cmdline = './matlab_run combineParameters %s' % (self._script_name )
		rcode = self.subprocess( cmdline + ' &> aout-%s-%d.log' % ( self._config_name, self._par ), path )
		
		name = None
		self._result = []


		name_output = 'aout-%s-%d.log' % ( self._config_name, self._par )

		if rcode == 0:
			self.state = SUCCESS
			self.addResult( '%s/ana' % self._config_name, self._root, name_output )
			#if 0 == system( 'stat %s/%s_p%d.dat &> /dev/null' % ( path, self._config_name, self._par ) ):
			#	f = open( '%s/%s_p%d.dat' % ( path, self._config_name, self._par ), 'r' )
			#	self._more_runs = int( f.readline() )
			#	f.close()
			#	system('rm -f %s/%s_p%d.dat' % (path, self._config_name, self._par) )
			#	name_output = 'aout-%s-%d' % ( self._config_name, self._par )
			#	system( 'mv %s/%s.log %s/%s' % ( self._root, name_output, self._root, name_output) )
				
			#	if 0 == system( 'stat %s/cache/%s_p%d.mat &> /dev/null' % ( path, self._config_name, self._par ) ):
			#		path = '%s/cache' % path
			#		name = '%s_p%d.mat' % ( self._config_name, self._par )
			#		self.addResult( '%s/ana' % self._config_name, path, name )

			#elif self._par > 0 and 0 == system( 'stat %s/cache/%s_p%d.mat &> /dev/null' % ( path, self._config_name, self._par ) ):
			#	path = '%s/cache' % path
			#	name = '%s_p%d.mat' % ( self._config_name, self._par )
			#	self.addResult( '%s/ana' % self._config_name, path, name )

			#elif self._par == 0 and 0 == system( 'stat %s/cache/%s.mat &> /dev/null' % ( path, self._config_name ) ):
			#	path = '%s/cache' % path
			#	name = '%s.mat' % self._config_name
			#	self.addResult( '', path, name )

			#else:
			#	self.state = ERROR
		else:
			self.state = ERROR
			name = '%s.m' % self._script_name
			self.addResult( '%s/err' % self._config_name, self._root, name )
			self.addResult( '%s/err' % self._config_name, self._root, name_output )
		#else:
		#	self.addResult( '%s/ana' % self._config_name, self._root, name_output )

	def getPar(self):
		return self._par

	def getConfig(self):
		return self._config_name

	def moreRuns(self):
		if not self._more_runs == None:
			return self._more_runs
		else:
			return 0
