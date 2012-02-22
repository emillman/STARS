from util import *
from time import sleep

context = {}

from experimentprocess import ExperimentProcess
from process import PROC_READY, PROC_WAIT, PROC_DONE, PROC_ERROR

from task import SUCCESS 

context['config'] = config = loadConfig('py/testProcess')

proc = ExperimentProcess(context, 0)

tasks = []

#print proc.state
if proc.state == PROC_READY:
	while not ( proc.state == PROC_ERROR or proc.state == PROC_DONE ):
		while proc.state == PROC_READY:
			task = proc.getTask()
			if not task == None:
				tasks.append( task )
			sleep( 5 )
		if proc.state == PROC_WAIT:
			print 'returning waiting tasks'
		
			while len( tasks ) > 0:
				task = tasks.pop(0)
				from matlabtask import MatlabTask
				from omnettask import OmnetTask
		
				if isinstance( task, MatlabTask ):
					task.state = SUCCESS
					task._more_runs = 3
				elif isinstance( task, OmnetTask ):
					task.state = SUCCESS

				proc.handleTask( task )
	

