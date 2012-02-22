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

function [ cache, variable ] = setCache( cache, variable, name )

    assert( isstruct( cache ), 'cache must be struct' );
    assert( isfield( cache, 'limit_bytes' ) && ...
        isfield( cache, 'current_bytes' ) && ...
        isfield( cache, 'map' ) && ...
        isfield( cache, 'meta' ), ...
        'cache is missing required fields' );

    % make sure variable can be placed in cache
    info = whos('variable');
    if info.bytes > ( cache.limit_bytes - cache.overhead_bytes  )
        warning('STARS:setCache','variable is %dBytes and exceeds cache size, will not be stored', info.bytes);
        return
    end
    if cache.current_bytes + info.bytes > ( cache.limit_bytes - cache.overhead_bytes  )
        cache = expireCache( cache, info.bytes );
    end


    if isKey( cache.meta, name );
        % only set dirty variables
        if isstruct( variable ) && isfield( variable, 'dirty' ) && variable.dirty
            variable = rmfield( variable, 'dirty' );
            remove(cache.map,name);
            meta = cache.meta(name);
            remove(cache.meta,name);
            cache.map(name) = variable;

            cache.current_bytes = cache.current_bytes + info.bytes - meta.bytes;
            meta.('bytes') = info.bytes;

            cache.meta(name) = meta;
        end
    else
        cache.map(name) = variable;
        cache.meta(name) = struct( 'bytes', info.bytes, 'count', 0, 'last', clock() );
        cache.current_bytes = cache.current_bytes + info.bytes;
        if isfield( variable, 'dirty' )
            variable = rmfield( variable, 'dirty' );
        end
    end
    
    % make sure something has not gone wrong, cache should never be larger
    % than the limit
    assert( cache.current_bytes <= ( cache.limit_bytes - cache.overhead_bytes  ), ...
        'cache is larger than it should be!' );
end