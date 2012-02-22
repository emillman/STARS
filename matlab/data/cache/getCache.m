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

function [ success, ... % true only if the data was loaded, disabled cache is false
    variable, ... % variable requested, undefined if success == false
    cache ] ... % cache pass-back for consistency
    = getCache( cache, ... % cache to check
    name ) % name of variable to load

    assert( isstruct( cache ), 'cache must be a struct' );
    
    assert( isfield( cache, 'map' ) && ...
        isfield( cache, 'meta' ), ...
        'cache struct is missing required fields');

    success = false;

    cache.tries = cache.tries + 1;
    
    try
        variable = cache.map(name);
        meta = cache.meta(name);
        
        meta.('last') = clock();
        meta.('count') = meta.count + 1;
        cache.meta(name) = meta;
        
        cache.hits = cache.hits + 1;
        variable.('cache_name') = name;
        success = true;
        %display(sprintf('cache hit: %s', name));
    catch me
        if strcmp(me.identifier,'MATLAB:Containers:Map:NoKey')
            %display(sprintf('cache miss: %s', name));
            variable = {};
        else
            context = struct('cache',cache,'cache_enabled',true');
            log_crashInfo( me, context );
            error('STARS:getCache','failed to get data associated with key: %s', name );
        end
    end

end