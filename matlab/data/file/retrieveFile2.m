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

function [ success ] = retrieveFile2( context, file )

    assert( isstruct( context ), 'context must be a struct' );
    assert( isfield( context, 'store_cache' ), 'context is missing required field' );
    assert( ~isempty( context.store_cache ), 'context.store_cache must be defined' );

    tries = 0;
    while tries < 4
        success = retrieveFile( context, file );
        if ~success
            if tries < 3
                tries = tries + 1;
                pause( 10 );
                warning('analysis:retrieveFile','failed to obtain needed data for %s parameter %d, try %d', context.config, context.parameter, tries );
            else
                success = false;
                break;
            end
        else
            if context.compress
                tmp = find( file == '/' );
                if ~isempty( tmp )
                    file = file(tmp(end)+1:end);
                end
                if length( file ) > 4 && strcmp( file(end-3:end), '.bz2' )
                    cmdline = sprintf('bunzip2 %s/%s', context.cache.store, file );
                elseif length( file ) > 7 && strcmp( file(end-6:end), '.tar.gz' )
                    cmdline = sprintf('tar xf %s/%s -C %s && rm -f %s/%s', ...
                    context.cache.store, file, context.cache.store, ...
                    context.cache.store, file );
                else
                    error('analysis:retrieveFile','unknown compressed data type for file %s', file );
                end
                if 0 ~= system( cmdline )
                    error('analysis:retrieveFile','failed to decompress needed data for %s parameter %d', context.config, context.parameter );
                else
                    break;
                end
            else
                break;
            end
        end
    end
end