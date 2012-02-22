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

from os import rename, chdir, getcwd, environ, listdir
from time import asctime

from util import *

class WorkfileHandler(object):
	
	_pm = None
	_rm = None
	_workpath = None

	def __init__( self, config, rmanager, pmanager ):
		self._pm = pmanager
		self._rm = rmanager

		self._workpath = '%s/work' % environ['PWD']

		if not config == None:
			if 'work_path' in config:
				self._workpath = config['work_path']

		self.display( OUTPUT_VERBOSE, 'initialized with work path of %s' % self._workpath )
		

	def _parseWorkfile( self, fileName ):
		self.display( OUTPUT_DEBUG, 'attempting to parse workfile %s' % fileName )
		config = {}
		
		f = open( fileName, 'r' )
		data = f.read()
		f.close()
		data = data.splitlines()
		config = {}
		name = ''
		order = 0
		block = False

		for line in data:
			line = line.strip()

			if line == '':
				continue

			if line.startswith('#') or line.startswith('//') or line.startswith( '%' ):
				continue
				
			if line.startswith('[') and line.endswith(']'):
				name = line.strip('[]')

				if name.lower().startswith('config') or name.lower().startswith('script'):
					block = True
				else:
					block = False

				config[ name ] = {}
				order = 0
				continue
			
			if block:
				config[ name ][ order ] = line
			else:
				line = line.split('=',1)

				field = None
				value = None

				if len(line) == 2:
					field = line[0].strip()
					value = line[1].strip()
				
				elif len(line) == 1:
					field = line[0].strip()
					value = None

				else:
					continue

				config[ name ][ field ] = value
				config[ name ][ order ] = field

			order = order + 1
		
		return config

	def _loadWorkfile(self):
		self.display( OUTPUT_VERBOSE, 'checking for new workfiles' )
		cwd = getcwd()
		files = listdir( self._workpath )
		chdir( self._workpath )
		for f in files:
			try:
				handler = self._selectHandler( f )
				result = False
				if not handler == None:
					try:
						result = handler( f )
					except:
						displayExcept()
						result = False
				
					chdir( self._workpath )

					if result:
						rename( f, '%s.loaded' % f )
					else:
						rename( f, '%s.invalid' % f )

					break
			except:
				displayExcept()
				chdir( self._workpath )
				rename( f, '%s.invalid' % f )

		chdir( cwd )

	def _selectHandler(self, fname ):

		if fname.startswith('.'):
			return None
		elif fname.endswith( '.loaded' ):
			return None
		elif fname.endswith('.invalid' ):
			return None
		elif fname.endswith( 'shutdown.clts' ):
			return self._handleShutdown
		elif fname.endswith( 'shutdown.now' ):
			return self._handleShutdownNow
		elif fname.endswith( '.stop' ):
			return self._handleStop
		elif fname.endswith( '.kill' ):
			return self._handleStopNow
		elif fname.endswith( '.priority' ):
			return self._handlePriority
		elif fname.endswith( '.workers' ):
			return self._handleWorkers
		elif fname.endswith( '.reserve' ):
			return self._handleReserve
		elif fname.endswith( '.release' ):
			return self._handleRelease
		else:
			return self._handleWorkfile

	def step(self):
		self.display( OUTPUT_VERBOSE, 'running step' )
		self._loadWorkfile()


	def _handleShutdown(self,fname):

		self.display( OUTPUT_MAJOR, 'received shutdown notification.' )
		self._pm.shutdown()
		self._rm.shutdown( False )
		
		return True

	def _handleShutdownNow(self,fname):

		self.display( OUTPUT_MAJOR, 'received shutdown now notification.' )

		self._pm.shutdown()
		self._rm.shutdown( True )

		return True	

	def _handleStop(self,fname):

		pid = int(fname.split('.')[0])

		self.display( OUTPUT_MAJOR, 'received process %d stop request.' % pid )

		self._pm.stopProc( pid )

		return True

	def _handleStopNow(self,fname):

		pid = int(fname.split('.')[0])

		self.display( OUTPUT_MAJOR, 'received process %d stop now request.' % pid )

		self._pm.stopProc( pid )
		self._rm.stopTasks( pid )

		return True

	def _handlePriority(self,fname):

		pid = int(fname.split('.')[0])
		pri = int(fname.split('.')[1])

		self.display( OUTPUT_MINOR, 'received change for process %d: %d priority' % (pid, pri ) )

		self._pm.setPriority( pid, pri )

		return True


	def _handleWorkers(self,fname):

		pid = int(fname.split('.')[0])
		wkr = int(fname.split('.')[1])

		self.display( OUTPUT_MINOR, 'received change for process %d: %d workers' % (pid, wkr ) )

		self._pm.setWorkers( pid, wkr )

		return True


	def _handleReserve(self,fname):

		wid = int(fname.split('.')[0])

		self.display( OUTPUT_MINOR, 'received reserve request for worker %d' % wid )

		self._rm.reserveWorker( wid )

		return True

	def _handleRelease(self,fname):

		wid = int(fname.split('.')[0])

		self.display( OUTPUT_MINOR, 'received release request for worker %d' % wid )

		self._rm.releaseWorker( wid )

		return True

	def _handleWorkfile(self,fname):

		config = self._parseWorkfile( fname )

		self.display( OUTPUT_MINOR, 'received workfile process to load %s' % fname )

		pid = self._pm.newProc( config )

		return not pid == None

	def display(self, level, text):
		display( level, 'Workfile Handler: %s' % text )
				
