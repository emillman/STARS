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

% this script creates the in memory cache struct to be used by the
% statistical analysis.
function [ cache ... % uninitialized cache struct or existing struct to duplicate
    ] = newCache( cache_primer ) % primer struct or existing cache struct

    assert( isstruct( cache_primer ), 'cache_primer parameter must be a struct' );
    assert( isfield( cache_primer, 'limit_bytes' ), 'cache_primer.limit_bytes missing' );
    assert( isfield( cache_primer, 'overhead_bytes' ), 'cache_primer.overhead_bytes missing' );

    cache = struct();

    % create the map object to hold variables
    cache.('map') = containers.Map();
    % create the map object to hold variable metadata
    cache.('meta') = containers.Map();
    % maximum amount of memory to be used by matlab
    cache.('limit_bytes') = cache_primer.limit_bytes;
    % amount of memory consumed by matlab and the analysis process
    cache.('overhead_bytes' ) = cache_primer.overhead_bytes;
    % initialize state variables for cache
    cache.('current_bytes') = 0;
    cache.('tries') = 0;
    cache.('hits') = 0;

end