%
% Copyright (C) 2011 Eamon Millman
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU Lesser General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License
% along with this program; if not, see <http://www.gnu.org/licenses/>.
%

% this function created the scheduler entry for the matlab job to submit to
% westgrid

function [ sched ] = getPbs(clusterHost, email, remoteDataLocation, ram, walltime, procs, dev )

% set the PBS parameters and options here.
% a full list of options is available from
% http://www.westgrid.ca/support/running_jobs#directives
% on orcinus procs must be the first parameter.
SubmitArguments=sprintf('-l nodes=%d:ppn=1,walltime=%s,pmem=%s,software=MDCE:%d -m bea -M %s', procs, walltime, ram, procs, email);
if dev % orcinus has a dev processing queue seperate from the main queue
    SubmitArguments=sprintf('%s,qos=debug', SubmitArguments );
end

% setup the scheduler, this is all westgrid code from getschedule.m from
% the matlab tutorial at
% http://www.aict.ualberta.ca/images/stories/aict/research/numstatsserver/matlab-westgrid/getschedule.m
% 
sched = findResource('scheduler','type','generic');
set(sched,'ClusterSize',1)
set(sched, 'ClusterOsType', 'unix');
set(sched,'HasSharedFilesystem',0)
set(sched,'ClusterMatlabRoot','/global/software/matlab-2009b')
set(sched,'GetJobStateFcn',@pbsGetJobState)
set(sched,'DestroyJobFcn',@pbsDestroyJob)
set(sched,'SubmitFcn',{@pbsNonSharedSimpleSubmitFcn,clusterHost,remoteDataLocation,SubmitArguments})
set(sched,'ParallelSubmitFcn',{@pbsNonSharedParallelSubmitFcn,clusterHost,remoteDataLocation,SubmitArguments})
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
%Change the following three lines
WestgridID='myWestgridID';
Email='myEmail@email_address';
nprocs='1';
SubmitArguments=strcat('-m bea -M ',Email,' -l walltime=00:05:00,procs=',nprocs,',software=MDCE:',nprocs');


VER=version('-release');

switch VER
  case '2009a'
   remoteMatlabRoot='/global/software/matlab-2009a';
  case '2009b'
   remoteMatlabRoot='/global/software/matlab-2009b';
  case '2010a'
   remoteMatlabRoot='/global/software/matlab-2010a';
  case '2010b'
   remoteMatlabRoot='/global/software/matlab-2010b';
  otherwise
   fprintf(' Matlab version %s is not supported\n',VER);
   return;
end
clusterHost=strcat(WestgridID,'@orcinus.westgrid.ca');
remoteDataLocation=strcat('/global/scratch/',WestgridID);
sched = findResource('scheduler','type','generic');
set(sched,'ClusterSize',1);
set(sched, 'ClusterOsType', 'unix');
set(sched,'HasSharedFilesystem',0);
set(sched,'ClusterMatlabRoot',remoteMatlabRoot);
set(sched,'GetJobStateFcn',@pbsGetJobState);
set(sched,'DestroyJobFcn',@pbsDestroyJob);
set(sched,'SubmitFcn',{@pbsNonSharedSimpleSubmitFcn,clusterHost,remoteDataLocation,SubmitArguments});
set(sched,'ParallelSubmitFcn',{@pbsNonSharedParallelSubmitFcn,clusterHost,remoteDataLocation,SubmitArguments});
%}