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

% this function saves the specified variable to the file specified
function [ context, ... % context passback, needed to keep cache synced
    variable ] = ... % variable passback
    saveVariable( context, ... % context for analysis
    variable, ... % variable to save
    name, ... % name of variable
    file ) % file to save variable to

    assert( isstruct( context ), 'context must be a struct' );
    assert( isstruct( variable ), 'variable must be a struct' );
    
    assert( isfield( context, 'cache' ) && ...
        isfield( context, 'store_path' ) && ...
        isfield( context, 'remote_store' ), ...
        'context is missing required fields' );

    % only write variable to file if it has the persist field set and is
    % dirty
    if isfield( variable, 'persist' ) && variable.persist && ...
            isfield( variable, 'dirty' ) && variable.dirty
        % handle saving of file when using remote_store by writing file to
        % temp_path first. also handle temp only files
        if context.remote_store || ( isfield( variable, 'temp' ) && variable.temp )
            [ path, file_name, ext ] = fileparts( file );
            local_file = [ context.temp_path filesep file_name ext ];
        % save variable to store directly
        else
            local_file = [ context.store_path filesep file ];
        end

        % make sure filesep is correct for the platform
        if isunix()
            local_file = strrep( local_file, '\', filesep );
        else
            local_file = strrep( local_file, '/', filesep );
        end

        % make sure directory to place file exists
        path = fileparts( local_file );
        if exist( path, 'dir' ) ~= 7
            mkdir( path );
        end

        % handle special case when name == 'context'
        old_context = context;
        try
            % try to append variable to existing file, or overwrite
            eval( sprintf('%s = rmfield(variable, {\''persist\'', \''dirty\''});', name ) );
            save( local_file, name, '-append', '-v7.3' );
        catch me
            % if the file did not exist to append to create it, failing to
            % save to file is a failure case
            try
                if strcmp( me.identifier, 'MATLAB:save:couldNotWriteFile' )
                    save( local_file, name, '-v7.3' );
                else
                    error('STARS:saveVariable','could not save %s to %s', name, local_file );
                end
            catch me
                error('STARS:saveVariable','could not save %s to %s', name, local_file );
            end
        end
        context = old_context;
        
        % store file in remote location if needed, never store temp data
        if context.remote_store && ( ~isfield( variable, 'temp' ) || ~variable.temp )
            if ~storeFile( context, file )
                error('STARS:saveVariable','unable to store file in remote_store' );
            end
        end
    end
    
    % if the variable is dirty update the cache
    if context.cache_enabled
        if isfield( variable, 'dirty' ) && variable.dirty
            context.cache = setCache( context.cache, variable, name );
        end
    end
    
    % strip off persist related fields, temp is not removed to ensure it is
    % never sent to the store
    if isfield( variable, 'persist' )
        variable = rmfield( variable, 'persist' );
    end
    if isfield( variable, 'dirty' )
        variable = rmfield( variable, 'dirty' );
    end
end