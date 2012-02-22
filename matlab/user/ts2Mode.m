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

function [ feature, ts ] = ts2Mode(feature)
    
    start = feature.context.tmin;
    stop = feature.context.tmax;
    
    times= [];
    while sum( times ) < stop
        times = [ times; random('exponential', 0.1, 5000, 1 ) ];
    end
    times = cumsum(times);
    times( times > stop ) = [];
    trans = start + random('uniform',150,stop/4);
    
    times = times(:);
    
    idx = find( times >= trans, 1 );
    
    values = -5*ones(size(times));
    if random('uniform',0,1,1,1) >= 0.5
        values(idx:end) = random('uniform', 0, 80, length( times )-idx+1, 1 );
    else
        values(idx:end) = random('exp', 5, length( times )-idx+1, 1 );
    end

    ts = struct('times', times, 'values', values, 't_ss', idx(1) );
end