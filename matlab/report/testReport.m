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

% this script generates visualizations of data based on one or more
% experiment conducted.

% name the features to generate analysis report on
features = {'test_2modes','test_Nmodes','test_mode_uni','test_mode_uni_discrete'};

% declare the data sources to use when generating report
% the sources can be 1D or 2D. In the 1D case a row cell-array will signify
% distinct data points to consider. In the 2D case a column cell-array will
% signify related data points showing variation of a parameter
sources = cell(1,1);

% the test considers only a single data point
sources{1,1} = {'Test',1,'c:\masters\store','-b','test'};

% generate the report figures based on the features and sources of data
%
featureReport( features, sources, ...
    false, ... % do not supress experiment level details (can crash matlab if done with many features and sources
    true, {0,0,0,0}, true, Inf, 0 ); % compact display to reduce number of figures, set to false for one figure per plot for use when saving to .eps
