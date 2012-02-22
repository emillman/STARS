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

% this function stores the specified file at the location specified
function [ success ] = removeFile( context, file )

    success = true;
    
    cache_path = context.cache.store;
    local_file = sprintf('%s/%s', cache_path, file );
    tmp = find( file == '/' );
    if ~isempty(tmp)
        file = file(tmp(end)+1:end);
        local_file = sprintf( '%s/%s', cache_path, file );
    end

    delete( local_file );
    
end