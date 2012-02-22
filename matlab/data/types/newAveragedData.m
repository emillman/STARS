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

function [ a_data ] = newAveragedData()

    a_data = struct();
    a_data.('stats') = nan;
    a_data.('mode_times') = {};
    a_data.('mode_values') = {};
    a_data.('mode_periods') = [];
    a_data.('mode_counts') = {};
    a_data.('raw_counts') = [];
    a_data.('raw_times') = [];
    a_data.('raw_values') = [];
    a_data.('raw_period') = nan;
    
end