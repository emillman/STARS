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

% this script creates the context struct used by the statistical analysis
% to control the process based on the user supplied script. furthermore, it
% creates the list of features which will be processed.
function [ context, ... % context struct used to control analysis process
            features ... % cell-array containing feature structs
            ] = makeContext( script ) % name of script containing analysis configuration

    assert( ~isempty( script ) && ischar( script ), 'script must be specified and a character array' );
    assert( isvarname( script ), 'script must be a valid matlab function name' );
    assert( exist( script ) == 2, 'script must be in current matlab path' );

    % initialize the context struct with default values and required fields.
    features = {};
    context = struct();
    init;
    
    % run the user specified script to set analysis specific context
    % parameters and list of features of analyze.
    try
        eval( script );
    catch me
        display(sprintf('error occured in user supplied script file: %s', script ));
        rethrow(me);
    end

    % enforce proper values for context parameters and features
    assert( iscell( features ), 'features must be of type cell' );
    assert( ~isempty( features ), 'script must specify at lest one feature to analyze' );
    
    assert( isstruct( context ), 'context must be a struct' );
    
    assert( isfield( context, 'remote_store' ), 'context is missing remote_store field');
    assert( islogical(context.remote_store) && ...
        length( context.remote_store ) == 1, ...
        'context.remote_store must be true/false' );
    assert( isunix() || (ispc() && ~context.remote_store), 'remote store location is not supported under windows' );
    
    assert( isfield( context, 'store_path' ), 'context is missing store_path field' );
    assert( ~isempty( context.store_path ) && ischar( context.store_path ), ...
        'context.store_path must be specified as a character array' );
    if ~context.remote_store
        if exist( context.store_path, 'dir' ) ~= 7
            mkdir( context.store_path );
            warning( 'STARS:makeContext','context.store_path could not be found, created %s', context.store_path );
        end
        %assert( exist( context.store_path, 'dir' ) == 7, 'context.store_path could not be found' );
    end
    assert( isfield( context, 'temp_path' ), 'context is missing temp_path field' );
    assert( ~isempty( context.temp_path ) && ischar( context.temp_path ), ...
        'context.temp_path must be specified as a character array' );
    if exist( context.temp_path, 'dir' ) ~= 7
        mkdir( context.temp_path );
        warning( 'STARS:makeContext','context.temp_path could not be found, created %s', context.temp_path );
    end
    %assert( exist( context.temp_path, 'dir' ) == 7, 'context.temp_path could not be found.' );
    
    assert( isfield( context, 'raw_compression' ), 'context is missing raw_compression field' );
    assert( context.raw_compression >= 0 && context.raw_compression <= 2, ...
        'context.raw_compression must be set to 0, 1, or 2' );
    assert( isunix() || (ispc() && context.raw_compression == 0), 'raw compression is not supported under windows.' );
    
    
    assert( isfield( context, 'cache_enabled' ), 'context is missing cache_enabled field');
    assert( islogical(context.cache_enabled) && ...
        length( context.cache_enabled ) == 1, ...
        'context.cache_enabled must be true/false' );
    if context.cache_enabled
        assert( isfield( context, 'cache' ), 'context is missing cache field' );
        assert( isstruct( context.cache ), 'context.cache must be of type struct' );
        assert( isfield( context.cache, 'limit_bytes' ), 'context.cache is missing limit_bytes field' );
        assert( context.cache.limit_bytes > 0, 'context.cache.limit_bytes must be > 0' );
        assert( isfield( context.cache, 'overhead_bytes' ), 'context.cache is missing overhead_bytes field' );
        assert( context.cache.overhead_bytes > 0 && ...
            context.cache.overhead_bytes < context.cache.limit_bytes, ...
            'context.cache.overhead_bytes must be > 0 and < context.cache.limit_bytes' );
        context.('cache') = newCache( context.cache  );
    end
    
    assert( isfield( context, 'repeat' ), 'context is missing repeat field' );
    assert( context.repeat > 0, 'context.repeat must be greater than 0.');
    assert( isfield( context, 'max_repeat' ), 'context is missing max_repeat field' );
    assert( context.max_repeat >= context.repeat, 'context.max_repeat must be >= context.repeat' );  
    assert( isfield( context, 'first_repeat'), 'context is missing first_repeat field' );
    assert( context.first_repeat > 0 && context.first_repeat <= (context.max_repeat+1), ...
        'context.first_repeat must be in the range [1,context.max_repeat+1]');
    
    assert( isfield( context, 'control_func' ), 'context is missing control_func field' );
    assert( ~isempty( context.control_func ) && ischar( context.control_func ), ...
        'context.control_func must be specified and a character array' );
    assert( exist( context.control_func ) == 2, 'context.control_func must be in the current matlab path' );
    
    assert( isfield( context, 'config' ), 'context is missing config field');
    assert( ~isempty( context.config ) && ischar( context.config ), ...
        'context.config must be specified and a character array' );
    assert( isfield( context, 'parameter' ), 'context is missing parameter field' );
    assert( context.parameter >= 0, 'context.parameter must be >= 0' )
    assert( isfield( context, 'parameters' ), 'context is missing parameters field' );
    assert( context.parameters > 0, 'context.parameters must be > 0' )
    assert( isfield( context, 'tmin' ), 'context is missing tmin field' );
    assert( context.tmin >= 0, 'context.tmin must be greater >= 0' );
    assert( isfield( context, 'tmax' ), 'context is missing tmax field' );
    assert( context.tmax > context.tmin, 'context.tmax must be > context.tmin' );
    assert( ~isinf( context.tmax ), 'context.tmax must be set, cannot be Inf' );
    
    assert( isfield( context, 'cpu' ), 'context is missing cpu field' );
    if matlabpool('size')
        assert( context.cpu > 0, 'context.cpu must be > 0 when matlabpool is open' );
        assert( context.cpu <= matlabpool('size'), 'context.cpu must be <= size of pool' );
    end
    
    assert( isfield( context, 'debug' ), 'context is missing debug field');
    assert( islogical(context.debug) && ...
        length( context.debug ) == 1, ...
        'context.debug must be true/false' );
    
    
    % initialize additional context parameters which should not be user
    % specified
    
    if isfield( context, 'runs' )
        warning( 'STARS:makeContext', 'context.runs is already defined, overwritten' );
    end
    lo = (context.parameter-1)*context.max_repeat;
    hi = lo + context.max_repeat -1;
    context.('runs') = lo:hi;
    
    if isfield( context, 'run' )
        warning( 'STARS:makeContext', 'context.run is already defined, removed' );
        context = rmfield( context, 'run' );
    end
    
    % context.script is set to be the name of the script passed in
    if isfield( context, 'script' )
        warning( 'STARS:makeContext', 'context.script is already defined, removed' );
        context = rmfield( context, 'script' );
    end
    context.('script') = script;
    
    
    % context.temp_path must be unique to each process, so make a random
    % directory
    context.temp_path = [ context.temp_path filesep randomdir ];
    try
        mkdir( context.temp_path );
    catch me
        display( sprintf('could not create temp_path: %s', context.temp_path ) );
        rethrow( me );
    end
end