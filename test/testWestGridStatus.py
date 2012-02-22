from util import *
from time import sleep
context = {}

from westgridstatusprocess import WestGridStatusProcess
from process import PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR

from task import SUCCESS 

config = loadConfig('workfiles/WestGridStatus')
print config

context['config'] = config

proc = WestGridStatusProcess(context, 0)

tasks = []

print proc.state
if proc.state == PROC_READY:
	while proc.state == PROC_READY:
		task = proc.getTask()
		if not task == None:
			tasks.append( task )
		sleep(0.25)
	

