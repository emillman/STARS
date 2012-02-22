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

from time import time, sleep
from mpi import size, rank, barrier, bcast

from managernode import ManagerNode
from workernode import WorkerNode
from shutdowntask import ShutdownTask

from os import system, getpid, environ
from subprocess import Popen

from nodefactory import createNode
from util import *

stop = False
node = None
goingdown = False

if size > 1:

	if rank == 0:
		stop = runningCheck()		
	stop = bcast( stop )
		

	if not stop:

		try:
			node = createNode('mpi')

		except:
			displayExcept()
			print 'fatal error creating node %d' % rank
			stop = True

		stop = bcast( stop )

	if not stop:

		t = time()
		d = 0.25

		while not node.done() and not stop:

			try:
				r = False

				if not node.done():
					r = node.step()

				c = time() - t
				t = time()

				if not r and c < d:

					sleep( d - c )

			except:
				displayExcept()
				stop = True

			if stop and not goingdown:
				task = ShutdownTask(-1,0,None)
				task.node = node
				node.handle( task )
				goingdown = True
		
	if not node == None:
		node.finish()	


else:

	print 'you must use more than one process.'
