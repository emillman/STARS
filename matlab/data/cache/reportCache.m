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

function [] = reportCache( cache )

    total_bytes = 0;
    display( 'Cache Usage Report' );
    sizes = [];
    for name = keys( cache.meta )
        info = cache.meta(name{1});
        sizes(end+1) = info.bytes;
        total_bytes = total_bytes + info.bytes;
        display( sprintf('Size %0.3fMB, Entry: %s', info.bytes / 1024^2, name{1} ) );
    end

    display( sprintf('Cache Capacity: %0.3f%%, Limit: %0.3fMB, Using: %0.3fMB', ...
        100*total_bytes/cache.limit_bytes, cache.limit_bytes/1024^2, total_bytes/1024^2));
    
    display( sprintf('Hits: %d Tries: %d - %0.3f%%', ...
        cache.hits, cache.tries, cache.hits/cache.tries*100 ) );
end