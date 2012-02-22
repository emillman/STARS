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

function [ cache ] = removeCache( cache, name )
    
    assert( isstruct( cache ), 'cache must be struct' );
    assert( isfield( cache, 'current_bytes' ) && ...
        isfield( cache, 'map' ) && ...
        isfield( cache, 'meta' ), ...
        'cache is missing required fields' );

    if isKey( cache.map, name )
        remove( cache.map, name );
        meta = cache.meta(name);
        remove( cache.meta, name );
        
        cache.current_bytes = cache.current_bytes - meta.bytes;
    end

end