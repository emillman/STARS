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

% this function determines if the specified timeseries data is valid
function [ valid ] = timeseriesValid( ts_data )

    valid = true;
    
    % valid time-series data is a struct
    if ~isstruct( ts_data )
        valid = false;
    end
    

    
    % it must have a times and values field of the same size and columns
    if valid && ...
            ~( isfield(ts_data,'times') && ...
               isfield(ts_data,'values') && ...
               size( ts_data.times, 2 ) == 1 && ...
               size( ts_data.times, 1 ) == size( ts_data.values, 1 ) && ...
               size( ts_data.times, 2 ) == size( ts_data.values, 2 ) )
          valid = false;
    end
    
    % it must contain data
    if valid && ...
            ~( ~isempty( ts_data.times ) && ~isempty( ts_data.values ) )
        valid = false;
    end
end