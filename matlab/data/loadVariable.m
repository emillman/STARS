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

% this function loads the specified variable from the file specified if
% found in the store or temp paths.
function [ success, ... % boolean, true if variable was loaded, false otherwise
    variable, ... % when true contains the request variable
    context ] = ... % passback of context, needed to keep cache synced
    loadVariable( context, ... % analysis context
    name, ... % name of variable to load
    file, ... % file to look for variable in
    temp_file ) % optional - file is temporary data and is not available in store_path

    assert( isstruct( context ), 'context must be a struct' );
    assert( isfield( context, 'cache' ) && ...
        isfield( context, 'store_path' ) && ...
        isfield( context, 'temp_path' ) && ...
        isfield( context, 'remote_store' ), ...
        'context is missing required fields' );
    
    assert( isvarname( name ), 'parameter name must be a valid matlab variable name' );

    % check if optional parameter temp_file is specified, if not assume it
    % is false.
    if isempty( whos('temp_file') )
        temp_file = false;
    end
    
    success = false;
    variable = [];
    
    if context.cache_enabled
        % check if our data is in memory
        [ success, variable, context.cache ] = getCache( context.cache, name );
    end
    
    % load from file if variable was not found in the cache
    if ~success
        % reset success to be failure by default
        success = false;
        % fetch from the remote store and put file in temp_path
        if context.remote_store || temp_file
            
            % file contains subpaths ana/r# or ana/p# which is not used
            % when loading from temp_path
            [ path, file_name, ext ] = fileparts( file );
            local_file = [ context.temp_path filesep file_name ext ];
            
            % only retrieve the file if it is not already in the path and
            % is not a temp file
            if exist( local_file, 'file' ) ~= 2
                if temp_file || ~retrieveFile( context, file )
                    % set local_file to invalid value if it could not be
                    % retrieved
                    local_file = '';
                end
            end
        % load variable directly from the store_path if it is local    
        else
            local_file = [ context.store_path filesep file ];
        end
        
        % make sure filesep is correct for the file to load
        if isunix()
            local_file = strrep( local_file, '\', filesep );
        else
            local_file = strrep( local_file, '/', filesep );
        end
        
        % attempt to load the variable from the local_file
        try
            load( local_file, name );
            eval( sprintf('variable = %s;', name ) );
            
            % make sure meta-fields related to persistance/cache are stripped off
            if isfield( variable, 'persist' )
                variable = rmfield( variable, 'persist' );
            end
            
            if isfield( variable, 'dirty' )
                variable = rmfield( variable, 'dirty' );
            end
            
            success = true;
        % failing to load the variable is not a crash condition
        catch me
            variable = [];
        end
        
    end
    
    if ~success
        display( sprintf( '-- could not load: %s', name ) );
    else
        if context.cache_enabled
            % push variable into the cache
            context.cache = setCache( context.cache, variable, name );
        end
    end

end