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

function [ st_info ] = newStationaryInfo()

    st_info = struct();
    st_info.('stationary') = false;
    st_info.('start_time') = nan;
    st_info.('start_idx') = nan;
    st_info.('window_width') = nan;
    st_info.('window_count') = nan;
    st_info.('edge_idxs') = [];
    st_info.('trace') = {};
    st_info.('failure_code') = nan;
    st_info.('chosen_width') = nan;
    
end