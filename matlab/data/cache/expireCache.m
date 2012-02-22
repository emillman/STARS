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

function [ cache ] = expireCache( cache, bytes_needed )

    removed_count = 0;
    removed_bytes = 0;
    
    while (cache.current_bytes + bytes_needed) > (cache.limit_bytes - cache.overhead_bytes)

        names = keys( cache.meta );
        if isempty(names)
            break;
        end
        infos = values( cache.meta );
        ages = nan( size( names ) );
        counts = nan( size( names ) );
        bytes = nan( size( names ) );

        for n = 1:length(names)
            info = infos{n};
            ages(n) = etime( clock(), info.last );
            counts(n) = info.count;
            bytes(n) = info.bytes;
        end

        [ v, idx ] = sort( ages, 'ascend' );

        name = names{idx(end)};

        cache = removeCache( cache, name );
        
        removed_count = removed_count + 1;
        removed_bytes = removed_bytes + infos{idx(end)}.bytes;
    end
    if removed_count > 0
        display(sprintf('-- removed %d items from cache, freed %d bytes', removed_count, removed_bytes ) );
    end
end