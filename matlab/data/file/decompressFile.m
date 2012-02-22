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

% this function decompresses the file specified according to the
% raw_compression field of the context parameter.
function [ success ] = decompressFile( context, file )

    assert( isstruct( context ), 'context must be of type struct' );
    assert( isfield( context, 'temp_path' ), 'context is missing required temp_path field' );
    assert( isfield( context, 'raw_compression' ), 'context is missing required raw_compression field' );
    assert( ~isempty( file ) && ischar( file ), 'file parameter cannot be empty and must be a character array' );
    
    % fail by default
    success = false;
    
    cmd_line = '';
    
    switch context.raw_compression
        case 0
            warning('STARS:decompressFile','called decompress when no compression is expected, doing nothing');
        case 1
            cmd_line = sprintf('tar zxf %s -C %s', file, context.temp_path );
        case 2
            [ path, file_name ] = fileparts( file );
            cmd_line = sprintf('bunzip2 -kc %s > %s/%s%s', file, context.temp_path, file_name );
    end
    
    if isempty( cmd_line ) || system( cmd_line ) == 0
        success = true;
    else
        error('STARS:decompressFile','failed to decompress file: %s', file );
    end
    
    % cleanup compressed file if we retrieved it from a remote_store
    % failing to delete if decompression succeeded is considered a failure.
    if context.remote_store && ~isempty( cmd_line )
        try
           delete( file );
        catch me
            if success
                rethrow( me );
            end
        end
    end

end