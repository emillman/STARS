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

function [ context ] = demoteFile( context, file )
    
    if isfield( context.cache, 'child' ) && context.cache.child
        
        names = keys(context.cache.meta);
    
        for n = 1:length(names)
            meta = context.cache.meta( names{n} );
            if isempty(meta.file) && isempty(file)
                if remove
                    context = removeCache( context, names{n} );
                end
            elseif strncmp( meta.file, file, min( length(meta.file), length(file) ) )
                variable = context.cache.map( names{n} );
                    variable = rmfield( variable, 'dirty' );
                    variable.('persist') = true;
                    variable.('expire') = false;
                    saveVariable( context, variable, names{n}, file );
                    context = storeFile( context, file );
            end
        end
        
        cache_path = context.cache.store;
        
        tmp = find( file == '/' );
        if ~isempty(tmp)
            file = file(tmp(end)+1:end);
        end
        
        cache_file = sprintf('%s/%s', cache_path, file );
        
        if isempty( find( file == '*',1 ) )
            if isunix()
                cmdline = sprintf('mv %s/../%s %s/%s', cache_path, file, cache_file );
            else
                cmdline = sprintf('mkdir %s & cd /D %s\\.. && move %s %s', strrep(cache_path,'/','\'), strrep(cache_path,'/','\'), file , strrep(cache_file,'/','\') );
            end
        else
            if isunix()
                cmdline = sprintf('mv %s/../%s %s/%s', cache_path, file, cache_path );
            else
                cmdline = sprintf('mkdir %s & cd /D %s\\.. && move %s %s', strrep(cache_path,'/','\'), strrep(cache_path,'/','\'), file , strrep(cache_path,'/','\') );
            end
        end
        if 0 == system( cmdline )
            display('demoted file to parent cache');
        else
            warning('analysis:promoteCache','tried to promote file which was not there');
        end
    else
        error('analysis:promoteCache','called promote on cache that is not child');
    end
    
end