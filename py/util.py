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

from time import asctime
from math import floor

from traceback import print_tb
from sys import exc_info
from os import environ, system, getpid

# used for major clts event output
OUTPUT_MAJOR = 1
# used for minor clts event output
OUTPUT_MINOR = 2
# used for clts logic output
OUTPUT_LOGIC = 4
# used for clts verbose output
OUTPUT_VERBOSE = 16
# used for clts error output
OUTPUT_ERROR = 128
# used for clts mpi related output
OUTPUT_MPI = 256
# used for clts debug output
OUTPUT_DEBUG = 1024

OUTPUT_LEVEL = OUTPUT_MAJOR | OUTPUT_MINOR | OUTPUT_ERROR
#OUTPUT_LEVEL = OUTPUT_MAJOR | OUTPUT_MINOR | OUTPUT_ERROR | OUTPUT_LOGIC | OUTPUT_DEBUG | OUTPUT_VERBOSE | OUTPUT_MPI

def display(level,text):
#	print 'called display'
	if not (OUTPUT_LEVEL & level) == 0:
		#print 'output is to be printed'

		#print 'checking for special output types'
		if not (OUTPUT_ERROR & level) == 0:
			print '**ERROR** [%s] %s' % ( asctime(), text )
		elif not( OUTPUT_DEBUG & level) ==0:
			print '--DEBUG-- [%s] %s' % ( asctime(), text )
		else:
			print '[%s] %s' % ( asctime(), text )

def displayExcept():
	print exc_info()[0]
	print exc_info()[1]
	print_tb(exc_info()[2])

def centerText(width,t):
	tl = len(t)
	os = int(width/2)

def timeText(t):
	SIM = float(60)
	SIH = float(60*SIM)
	SID = float(24*SIH)

	dd = floor( t / SID )
	t = t - SID*dd

	hh = floor( t / SIH )
	t = t - SIH*hh

	mm = floor( t / SIM )
	ss = floor(t - SIM*mm)

	line = ''
	if dd > 0:
		line = '%s%dd' % (line, dd)

	if hh > 0:
		line = '%s%02dh' % (line, hh)

	if mm > 0:
		line = '%s%02dm' % (line, mm)

	if ss > 0:
		line = '%s%02ds' % (line, ss)

	return line
	
def runningCheck():
    stop = False
    try:
        display( OUTPUT_MINOR, 'Checking for already running instance' )
        if system( 'stat testing &> /dev/null' ) == 0:
            display( OUTPUT_MINOR, 'starting framework in testing mode' )
        else:
            if system( 'stat .pid &> /dev/null' ) == 0:
                fid = open( '.pid' )
                rpid = int(fid.read())
                fid.close()

                display( OUTPUT_MINOR, 'run record found, checking for process %d' % rpid )
                cmdline = 'top -b -n 1 -d 0 | grep -E "%d %s .* pyMPI" &> /dev/null' % ( rpid, environ['USER'] )

                #display( OUTPUT_DEBUG, cmdline )
                rcode = system( cmdline )
                #display( OUTPUT_DEBUG, rcode )
                if 0 == rcode:
                    display( OUTPUT_MAJOR, 'framework is already running' )
                    stop = True
                else:
                    display( OUTPUT_MINOR, 'run record is not valid, continuing to load framework.' )

        if not stop:
            system( 'echo %d > .pid' % getpid() )

    except:
        displayExcept()
        stop = True

    return stop

def loadContext( fileName ):
	return loadConfig( fileName )

def loadConfig( fileName ):
	display( OUTPUT_DEBUG, 'attempting to parse config %s' % ( fileName ) )
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
