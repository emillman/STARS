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

% this function loads the specified raw data fields and filters them using
% the key parameter, if specified.
function [ feature, data ] = loadRawData( feature, fields, key )

    assert( featureValid( feature ), 'feature must be struct' );
    assert( isfield( feature, 'context' ), 'feature is missing context field' );
    assert( ~isempty( fields ), 'fields must contain atleast one value' );
    if ~isempty( whos('key') )
        assert( isempty( key ) || islogical( key ), 'key must be a logical vector if it is specified' );
    else
        key = [];
    end
    
    % matlab uses 1:N indexing, fields are indexed 0:N-1, correct for this
    % here to simplify coding in tsFunctions.
    fields = fields - 1;

    data = cell( max( fields ), 1 );
    
    file_path = [ feature.context.config filesep 'sim' filesep sprintf('r%d', feature.context.run) ];
    
    % when using compression=1 all fields for a given instrument are
    % packaged together as a single compressed file. it must be fetched and
    % decompressed prior to looping over the fields
    if feature.context.raw_compression == 1

        % build file variable for tar.gz
        file = sprintf( '%s_%s_r%d.tar.gz', feature.prefix, feature.context.config, feature.context.run );
        file = [ file_path filesep file ];
        
        % handle fetching of the remote file
        if feature.context.remote_store
            [ path, file_name, ext ] = fileparts( file );
            local_file = [ context.temp_path filesep file_name ext ];
            
            if exist( local_file, 'file' ~= 2 )
                if ~retrieveFile( feature.context, file )
                    error('STARS:loadRawData','unable to obtain raw file: %s%s%s', feature.context.store_path, filesep, file );
                end
            end
        else
            local_file = [ feature.context.store_path filesep file ];
        end
        
        if ~decompressFile( feature.context, local_file )
            error('STARS:loadRawData','failed to decompress raw file: %s', local_file );
        end
    end
    
    % load each of the fields one at a time
    for f = 1:length( fields )
        
        % fetching the raw data file for the current field is little
        % complex. if it is compressed=2 we must first decompress the file
        % which places it in the temp_path even if we remote_store=false
        file = sprintf( '%s%d-%s-%d.log', feature.prefix, fields(f), ...
            feature.context.config, feature.context.run );
        file = [ file_path filesep file ];
        if feature.context.raw_compression == 2
            file = [ file '.bz2' ];
        end
        
        if feature.context.remote_store
            [ path, file_name, ext ] = fileparts( file );
            local_file = [ feature.context.temp_path filesep file_name ext ];
            
            if exist( local_file, 'file' ) ~= 2
                if ~retrieveFile( feature.context, file )
                    error('STARS:loadRawData','unable to obtain raw file: %s%s%s', feature.context.store_path, filesep, file );
                end
            end
        else
            local_file = [ feature.context.store_path filesep file ];
        end
        
        if feature.context.raw_compression == 2
            if ~decompressFile( feature.context, local_file )
                error('STARS:loadRawData','failed to decompress raw file: %s', local_file );
            end
        end
        
        % load the raw field data
        file = sprintf('%s%d-%s-%d.log', feature.prefix, fields(f), ...
            feature.context.config, feature.context.run );
        file = [ file_path filesep file ];
        
        % if the file is remote or was decompressed then it is in the temp_path
        if feature.context.remote_store || feature.context.raw_compression > 0
            [ path, file_name, ext ] = fileparts( file );
            local_file = [ feature.context.temp_path filesep file_name ext ];
        else
            local_file = [ feature.context.store_path filesep file ];
        end
        
        % remember that fields = fields -1, so correct to handle MATLAB
        % indexing here when loading raw field.
        [ success, data{fields(f)+1} ] = loadRawField( local_file, key );
        if ~success
            error('STARS:loadRawData','could not load %s', file);
        end
    end
end
