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

from controltask import ControlTask
from task import NEW, SUCCESS, ERROR

from os.path import split, exists, dirname
from os import mkdir, path, getcwd, chdir, remove, listdir, system, environ, stat
from shutil import rmtree, move
from tarfile import TarFile
from sys import path, exc_info

from util import *

class DeployTask(ControlTask):

	def __init__(self,*args,**kwargs):

		ControlTask.__init__(self, *args, **kwargs )

		if len(args) == 4:
			self.display( OUTPUT_DEBUG, 'calling initializer for DeployTask' )
			self._initDeployTask( args[3] )

	def _initDeployTask(self, workers):

		if 'general' in self._config and 'localresources' in self._config['general']:
			fi = stat( self._config['general']['localresources'] )
			self.display( OUTPUT_MINOR, 'deploying process %d resources to worker nodes %s (%0.3fMB/ea)' % ( self.pid, str(workers.keys()) ,fi.st_size/1024.0/1024.0 ) )
			for k in workers.keys():
				n = workers[k]
				remote_host = str(n)
				remote_root = "%s/dep/%d" % ( environ['STARSPATH'], k )
				filePath = dirname( self._config['general']['localresources'] )
				fileName = split( self._config['general']['localresources'] )[1]
				if not self._data_access.deploy( filePath, fileName, remote_host, remote_root, '%d.tar.gz' % self.owner ):
					self.display( OUTPUT_ERROR, 'failed to send resources to worker: %s' % k )
					self.state = ERROR
					break

	def execute(self):
		self.display( OUTPUT_DEBUG, 'deploy task execuiting under %s' % self._root )
		rmtree( self._root + '/', ignore_errors=True )
		system( 'mkdir -p %s/' % self._root )
		
		if not self.pid in self.node._procs:
			self.display( OUTPUT_DEBUG, 'adding process to node list' )
			self.node._procs[ self.pid ] = self._root

		
		if 'general' in self._config and 'localresources' in self._config['general']:
			self.display( OUTPUT_DEBUG, 'setting up local resources' )
			cwd = getcwd()
			chdir( self._root )
			
			fname = '%s.tar.gz' % self._root

			system( 'tar zxf %s' % fname )

			#tf = TarFile.open( self._root + '.tar.gz' )
			#tf.extractall( self._root + '/' )
			#tf.close()

			chdir( cwd )

			remove( self._root + '.tar.gz' )

			if 'modulepath' in self._config['general']:
				files = listdir( self._root + '/' + self._config['general']['modulepath'] )
				for f in files:
					if f.endswith( '.py' ):
						move( self._root + '/' + self._config['general']['modulepath'] + '/' + f, self._root )

				if path.count( self._root ) == 0:
					path.append( self._root )	

			self.display( OUTPUT_DEBUG, 'process %d resources deployed.' % self.owner )

		self._config = None

		self.state = SUCCESS

	def finish(self):
		self.node.workers[ self.sender ]['proc'].append( self.pid )

		return True
