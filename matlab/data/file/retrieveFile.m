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

% this function retrieves the specified file at the location specified
function [ success ] = retrieveFile( context, file )

    assert( isstruct( context ), 'context must be a struct' );
    assert( isfield( context, 'store_path' ), 'context is missing required field' );
    assert( ~isempty( context.store_path ), 'context.store_path must be defined' );

    % fail by default
    success = false;
    
    if ~context.remote_store
        warning('STARS:retrieveFile','cannot retrieve a file when not using a remote store, ignoring call' );
    else
        split_idx = find( context.store_path == ':', 1 );
        if ~isempty( split_idx )
            host_name = context.store_path(1:split_idx-1);
            remote_path = context.store_path(split_idx+1:end);
            [ path, file_name, ext ] = fileparts( file );
            cmd_line = sprintf( 'scp %s:%s/%s %s/%s%s > /dev/null', host_name, remote_path, file, ...
                context.temp_path, file_name, ext );
            
            if system( cmd_line ) == 0
                success = true;
            end
        else
            warning('STARS:retrieveFile','store_path does not appear to be a remote location, ignoring call');
        end
    end
    
end