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

% this script defines the context parameters used by the analysis process
% and their default values. In cases where these parameters must be user
% specified an invalid default value is given. This script should only be
% called in makeContext(...) function.

% these context parameters define where and how to access/store data
%
% true if store_path is on remote system, false if local
context.('remote_store') = false;
% this is the absolute path to the data store
context.('store_path') = '';
% this is the absolute path to place temporary data
% a random directory will be created under this path to avoid conflicts
% with other analysis runs or parfar
context.('temp_path') = '';
% this context parameter defines the type of compression used on the raw
% data produced by the simulator instrumentation.
% 0 - uncompressed, 1 - tar.gz, 2 - bz2
context.('raw_compression') = 0;

% these context parameters define how to deal with the in memory variable
% cache used to minimize loading from store_path
%
% is the cache enabled, this is needed for performance reasons but on pre
% 2007 releases it is not available.
context.('cache_enabled') = true;
% declare the cache parameter
context.('cache') = struct();

if context.cache_enabled
    
    if ispc() % auto-detection of available memory is windows only
        mem_struct = memory;

        % maximum amount of memory matlab should be using for analysis, by default
        % it uses the maximum possible amount.
        context.cache.('limit_bytes') = mem_struct.MemAvailableAllArrays;
        % amount of memory matlab needs to perform analysis
        context.cache.('overhead_bytes') = mem_struct.MemUsedMATLAB;

        clear mem_struct;
    else
        context.cache.('limit_bytes') = 0;
        context.cache.('overhead_bytes') = 0;
    end
end

% these parameters define how many samples are to be processed by the
% statistical analysis and when they will be processed.
%
% the number of repeats available to process
% repeat > 0
context.('repeat') = 0;
% the maximum number of repeats to process, max_repeat >= repeat
context.('max_repeat') = context.repeat;
% the first repeat to process, allows skipping past earlier data runs if
% analysis is run after increasing the number of samples.
% 0 < first_repeat < max_repeat
context.('first_repeat') = 1;
% specifies the control function which is used to calculate how many more
% repeats are needed if analysis is run again.
% default function returns: max_repeat - repeat
context.('control_func') = 'analysisControl';

% these context parameters define the raw data to analyze
%
% configuration name of the simulation data and must be unique 
% with respect to store_path
context.('config') = '';
% parameter number of analysis to perform
% 0 - when calling combineParameters, 1+ when calling analyzeParameter
context.('parameter') = -1;
% number of parameters in the experiment, this is used by combineParameters
context.('parameters') = -1;

% these context parameters define the interval of time over which to
% perform statistical analysis on data.
%
% start of time, tmin >= 0
context.('tmin') = 0;
% end of time, tmax > tmin
context.('tmax') = Inf;

% these context parameters control the debug behaviour of the analysis
% process
%
% enable debug functions
context.('debug') = false;

% these context parameters control the statistical analysis performed using
% the distributed computing toolbox
%
% the maximum number of workers to use when using parfor
context.('cpu') = 0;

% these context parameters are used internally by the analysis and should
% not be user set.
%
% the current run for the repeat being analyzed
% context.('run') = nan; 
% the array of run numbers mapping from repeat to run
% context.('runs') = []; 