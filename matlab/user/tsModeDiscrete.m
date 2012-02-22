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

function [ feature, ts ] = tsModeDiscrete(feature)
    
    start = feature.context.tmin;
    stop = feature.context.tmax;

    times= [];
    while sum( times ) < stop
        times = [ times; random('exponential', 0.1, 5000, 1 ) ];
    end
    times = cumsum(times);
    times = times(:);
    
    values = random('unid', 10, length( times ), 1 );
    
    ts = struct('times', times, 'values', values );
end