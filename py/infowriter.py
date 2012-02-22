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

from os import environ, system
from time import time, asctime

from process import PROC_READY, PROC_ERROR, PROC_WAIT, PROC_DONE, PROC_STOP

from util import *

class InfoWriter(object):

	_rm = None
	_pm = None
	_frmk = None
	_root = None
	_start = None

	info_hdrtop = '_----------------------------------------------------------------------------------------_'
	info_hdrbot = '|________________________________________________________________________________________|'
	info_sep    = '|----------------------------------------------------------------------------------------|'
	
	def __init__(self,config,rmanager,pmanager,frmk):
		self._start = time()
		self._rm = rmanager
		self._pm = pmanager
		self._frmk = frmk
		self._root = '%s/log/' % environ['PWD']

		self.display( OUTPUT_VERBOSE, 'initialized' )

	def step(self):
		self.display( OUTPUT_VERBOSE, 'running step in info writer' )

		self._writeInfo()


	def _writeInfo(self):
		self.display( OUTPUT_VERBOSE, 'writing information' )

		f = open( '%s/info.new' % self._root, 'w' )

		f.write( '%s\r\n' % self.info_hdrtop )
		if self._rm.done() == True:

			line = '| System shutdown as of %s - uptime was %s' % (asctime(), timeText(time() - self._start) )
			f.write( '%s\r\n' % line )

		else:		
			line = '| System running as of %s - uptime: %s' % (asctime(), timeText(time() - self._start) )
			f.write( '%s\r\n' % line )

		f.write( '%s\r\n' % self.info_hdrbot )
		
		if self._rm.done() == False:

			if len( self._frmk.workers ) > 0:
				self._writeWorkerInfo( f )

				if len( self._pm._tracking ) > 0:
					f.write( '%s\r\n' % self.info_sep )


			if len( self._pm._tracking ) > 0:
				self._writeProcessInfo( f )

		f.close()
		system( 'mv %s/info.new %s/info.log' % (self._root, self._root) )
		

	def _writeWorkerInfo(self,f):
		line = '| Worker Resource Information'
		f.write( '%s\r\n' % line )
		f.write( '%s\r\n' % self.info_sep )

		wrote = False
		reserved = False

		for wid in self._frmk.workers.keys():
			info = self._frmk.workers[wid]
			if not info['reserved']:
				line = '| %d: host: %s has %d of %d slots free' % ( wid, info['name'], info['slots'], info['mslots'] )
				f.write( '%s\r\n' % line )
				wrote = True
			else:
				reserved = True

		if wrote:
			f.write( '%s\r\n' % self.info_sep )

		if reserved:
			line = '| Reserved Workers'
			f.write( '%s\r\n' % line )
			f.write( '%s\r\n' % self.info_sep )
			for wid in self._frmk.workers.keys():
				info = self._frmk.workers[wid]
				if info['reserved']:
					line = '| %d: host: %s has %d of %d slots free' % ( wid, info['name'], info['slots'], info['mslots'] )
					if info['slots'] == info['mslots']:
						line = '%s and is READY' % line
					else:
						line = '%s waiting for tasks to complete.' % line
					f.write( '%s\r\n' % line )

	def _writeProcessInfo(self,f):
		line = '| Process Information'
		f.write( '%s\r\n' % line )

		if len( self._pm._tracking ) == 0:
			f.write( '%s\r\n' % self.info_sep )

		for pid in self._pm._tracking:
			info = self._pm._tracking[pid]

			f.write( '%s\r\n' % self.info_sep )
			line = '| id %d: (%s) %s' % ( pid, info['config']['general']['modulename'], info['name'])
			f.write( '%s\r\n' % line )
			line = '| priority %d with minimum workers %d' % ( info['priority'], info['workers'] )
			f.write( '%s\r\n' % line )
			line = '| %d tasks have been issued, %d are out' % ( info['issued'], len( info['out'] ) )
			f.write( '%s\r\n' % line )
			line = '| created %s ago and' % timeText( time() - info['started'] )
			if info['state'] == PROC_READY:
				line = '%s is ready' % line
			elif info['state'] == PROC_DONE:
				line = '%s is done' % line
			elif info['state'] == PROC_ERROR:
				line = '%s encountered an error' % line
			elif info['state'] == PROC_WAIT:
				line = '%s is waiting' % line
			elif info['state'] == PROC_STOP:
				line = '%s is stopping' % line
			else:
				line = '%s is in an unknown state.'

			f.write( '%s\r\n' % line )

			if len( info['out'] ) > 0:
				f.write( '%s\r\n' % self.info_sep )
				line = ''

				for t in info['out'].keys():
                                        rinfo = self._rm._tracking[pid]
                                        if t in rinfo['noderef']:
                                                wid = rinfo['noderef'][t]
                                                entry = 'id %s: %s out %s on %s' % ( str(t), info['ref'][t].id() , timeText(time() - info['out'][t]), self._frmk.workers[wid]['name'] )
                                        else:
                                                entry = 'id %s: %s out %s' % ( str(t), info['ref'][t].id() , timeText(time() - info['out'][t]) )

					if line == '':
						line = entry
			
					elif len( line +  entry ) + 1 < 80:
						line = '%s %s' % (line,  entry)

					else:
						f.write( '%s\r\n' % line )
						line =  entry

				if not line == '':
					f.write( '%s\r\n' % line )

				else:
					f.write( '%s\r\n' % line )

		f.write( '%s\r\n' % self.info_sep )

	def display(self,level,text):
		display( level, 'Info Writer: %s' % text )
