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

% edit experiment/matlab/user/templateScript.m and set the proper
% remote_store = location to obtain remote data
% store = location to find input data and to place output

% the test feature has only one parameter, set to 1
% the analyzeParameter processes one parameter at a time

analyzeParameter('randomScript');

% merge parameter results into a single file
combineParameters('randomScript');

% print the report detailing the test feature
% first we need to initialize the context.
features = {};
eval('randomScript');
testReport;