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

function [ cache ] = flushCache( cache )

    assert( isstruct( cache ), 'cache much be struct' );
    assert( isfield( cache, 'meta' ), ...
        'cache is missing required fields' );

    names = keys(cache.meta);
    
    for n = 1:length(names)
        meta = cache.meta( names{n} );
        % remove cache entries with no file only if we say file=''
        cache = removeCache( cache, names{n} );
    end
end