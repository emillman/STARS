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
from os import environ

from util import *

class DataAccess(object):

	_global = None
	_store_path = None
	_store_host = None
	_config = None
	_host = None

	_ssh_o = None

	def __init__(self, configFile):

		try:
			self._config = loadConfig( configFile )
		except:
			self._config = None

		strict = False
		key = None
		if not self._config == None and 'dataaccess' in self._config:
			if 'global' in self._config['dataaccess']:
				self._global = True
			else:
				self._global = False

			if 'store_path' in self._config['dataaccess']:
				self._store_path = self._config['dataaccess']['store_path']
			else:
				raise Exception('DataAccess','required field [dataaccess]:store_path not found in %s' % configFile )

			if 'store_host' in self._config['dataaccess']:
				self._store_host = self._config['dataaccess']['store_host']
			elif not self._global:
				raise Exception('DataAccess','required field [dataaccess]:store_host not found in %s' % configFile )

			if 'key' in self._config['dataaccess']:
				key = self._config['dataaccess']['key']

			if 'StrictHostKeyChecking' in self._config['dataaccess']:
				strict = True

		if system( 'stat %s/hostname &> /dev/null' % environ['STARSPATH'] ) == 0:
			f = open( environ['STARSPATH'] + '/hostname' )
			self._host = f.read().strip()
			f.close()
		else:
			self._host = environ['HOSTNAME']
		self._ssh_o = ''

		if not strict:
			self._ssh_o = '-o StrictHostKeyChecking=no'
		if key == None:
			self._shh_o = '-i %s %s' % ( key, self._ssh_o )

	def setStore(self, storeHost, storePath, storeGlobal):
		#if not storeHost == None:
		self._store_host = storeHost
		#if not storePath == None:
		self._store_path = storePath
		#if not storeGlobal == None:
		self._global = storeGlobal
		display( OUTPUT_DEBUG, "data_access configured for store host %s, store path %s, and global %s." % ( storeHost, storePath, str(storeGlobal) ) )


	def store(self,subPath,fileHost,filePath,fileName):
                cmdline = "exit 1"
                result = False

		display( OUTPUT_DEBUG, "data_access.store called" )

                if not fileName.find('*') == -1:
			display( OUTPUT_DEBUG, "data_access.store multiple files" )
                        if self._global:
				display( OUTPUT_DEBUG, "data_access.store local file" )
                                cmdline = "cp %s/%s %s/%s/" % ( filePath, fileName, self._store_path, subPath )
                        else:
                                if not fileHost == None:
					display( OUTPUT_DEBUG, "data_access.store remote file, remote store" )
                                        cmdline = "scp %s %s:%s/%s %s:%s/%s/" % ( self._ssh_o, fileHost, filePath, fileName, self._store_host, self._store_path, subPath )
                                else:
					display( OUTPUT_DEBUG, "data_access.store remote file, local store" )
                                        cmdline = "scp %s %s/%s %s:%s/%s/" % ( self._ssh_o, filePath, fileName, self._store_host, self._store_path, subPath )
                else:
			display( OUTPUT_DEBUG, "data_access.store single file" )
                        if self._global:
				display( OUTPUT_DEBUG, "data_access.store local file" )
                                cmdline = "mv %s/%s %s/%s/%s" % ( filePath, fileName, self._store_path, subPath, fileName )
                        else:
                                if not fileHost == None:
					display( OUTPUT_DEBUG, "data_access.store remote file, remote store" )
                                        cmdline = "scp %s %s:%s/%s %s:%s/%s/" % ( self._ssh_o, fileHost, filePath, fileName, self._store_host, self._store_path, subPath )
                                else:
					display( OUTPUT_DEBUG, "data_access.store remote file, local store" )
                                        cmdline = "scp %s %s/%s %s:%s/%s/" % ( self._ssh_o, filePath, fileName, self._store_host, self._store_path, subPath )

		display( OUTPUT_DEBUG, 'data_access' )                
		self.touchPath( self._store_host, "%s/%s" % (self._store_path, subPath) )

                display( OUTPUT_DEBUG, "running: %s" % cmdline )

                if 0 == system( cmdline + ' &> /dev/null' ):
                        result = True

		if result:
			if not fileHost == None:
				display( OUTPUT_MINOR, "stored file %s:%s/%s in store:%s/" % ( fileHost, filePath, fileName, subPath ) )
			else:
				display( OUTPUT_MINOR, "stored file %s/%s in store:%s/" % ( filePath, fileName, subPath ) )

		return result

	def remove(self,fileHost,filePath,fileName):
		cmdline = 'exit 1'
		result = False

		if self._global or fileHost == None:
			cmdline = "rm -f %s/%s" % ( filePath, fileName )
		else:
			cmdline = "ssh %s %s 'rm -f %s/%s'" % ( self._ssh_o, fileHost, filePath, fileName )

		display( OUTPUT_DEBUG, 'running: %s' % cmdline )

		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_MINOR, "removed %s" % fileName )

	def retrieve(self,subPath,filePath,fileName):
		cmdline = "exit 1"
		
		result = False

		if self._global:
			cmdline = "ln -s %s/%s/%s %s/%s" % ( self._store_path, subPath, fileName, filePath, fileName )
		else:
			cmdline = "scp %s %s:%s/%s/%s %s/%s" % ( self._ssh_o, self._store_host, self._store_path, subPath, fileName, filePath, fileName )

		self.touchPath( None, filePath )

		display( OUTPUT_DEBUG, "running: %s" % cmdline )
		
		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_MINOR, "retrieved file %s from store:%s/" % ( fileName, subPath ) )
			result = True

		return result

	def deploy(self,filePath,fileName,destHost,destPath,destName):
		cmdline = "exit 1"
		result = False
		if self._global:
			cmdline = "cp %s/%s %s/%s" % ( filePath, fileName, destPath, destName )
		else:
			cmdline = "scp %s %s/%s %s:%s/%s" % ( self._ssh_o, filePath, fileName, destHost, destPath, destName )

		self.touchPath( destHost, destPath )

		display( OUTPUT_DEBUG, "running: %s" % cmdline )

		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_MINOR, "deployed file %s to %s:%s" % ( fileName, destHost, destPath ) )
			result = True
		return result

	def collect(self,filePath, fileName, srcHost, srcPath, srcName ):
		cmdline = "exit 1"
		result = False
		if self._global or srcHost == None:
			cmdline = "ln -s %s/%s %s/%s" % (srcPath, srcName, filePath, fileName )
		else:
			cmdline = "scp %s %s:%s/%s %s/%s" % ( self._ssh_o, srcHost, srcPath, srcName, filePath, fileName )

		self.touchPath( None, filePath )

		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_MINOR, "collected file %s/%s from %s:%s" % ( filePath, fileName, srcHost, srcPath ) )
			result = True
		return result

	def checkStore(self,subPath, fileName ):
		cmdline = "exit 1"
		result = False

		if self._global:
			cmdline = "stat %s/%s/%s" % ( self._store_path, subPath, fileName )
		else:
			cmdline = "ssh %s %s 'stat %s/%s/%s'" % ( self._ssh_o, self._store_host, self._store_path, subPath, fileName )

		display( OUTPUT_DEBUG, "running: %s" % cmdline )

		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_DEBUG, "found file %s in store:%s/" % ( fileName, subPath ) )
			result = True
		return result

	def touchPath(self,fileHost,filePath):
		cmdline = "exit 1"
		display( OUTPUT_DEBUG, "data_access.touchPath called" )
		if self._global or fileHost == None:
			display( OUTPUT_DEBUG, "data_access.touchPath local path" )
			cmdline = "mkdir -p %s" % filePath
		else:
			display( OUTPUT_DEBUG, "data_access.touchPath remote path" )
			cmdline = "ssh %s %s 'mkdir -p %s'" % ( self._ssh_o, fileHost, filePath )

		display( OUTPUT_DEBUG, "running: %s" % cmdline )
		
		if 0 == system( cmdline + ' &> /dev/null' ):
			display( OUTPUT_DEBUG, "touched %s" % filePath )
