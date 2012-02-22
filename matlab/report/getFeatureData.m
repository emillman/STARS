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

function [ contexts, infos, cdfs ] = getFeatureData( names, sources )

    contexts = {};
    infos = {};
    cdfs = {};

    % to avoid huge overhead sources are pre-loaded to minimize loading
    % from .mat files. this places an increased demand on available memory
    % but greatly improves load times (orders of magnitude). if memory
    % problems reducing the number of features reported at a time will
    % side-step the issue at the cost of more .mat loads.
    mat_files = {};
    mat_parameters = {};
    mat_source_map = {};
    for r = 1:size(sources,1)
        for c = 1:size(sources,2)
            if isempty(sources{r,c})
                continue;
            end
            
            same_source = 0;
            mat_file_name = sprintf( '%s/%s.mat', sources{r,c}{3}, sources{r,c}{1} );
            % check if the source is known
            for f = 1:length( mat_files )
                
                if strcmp( mat_files{f}, mat_file_name )
                    same_source = f;
                    break; % known source
                end
            end
            % update a known source or add a new one
            if same_source > 0
                parameter_count = length( mat_parameters{same_source} );
                mat_parameters{same_source} = unique( [ mat_parameters{same_source} sources{r,c}{2} ] );
                % handle many-to-many
                if parameter_count == length( mat_parameters{same_source} );
                    mat_source_map{same_source, sources{r,c}{2}} = [ mat_source_map{same_source, sources{r,c}{2}} r c];
                else
                    mat_source_map{same_source, sources{r,c}{2}} = [r c];
                end
            else
                mat_files{end+1} = mat_file_name;
                mat_parameters{length(mat_files)} = [sources{r,c}{2}];
                mat_source_map{length(mat_files), sources{r,c}{2}} = [r c];
            end
        end
    end
    
    display(sprintf('identified %d mat files used by sources', length( mat_files ) ) );
    
    % load all feature data for each source and parameter then store in the
    % appropriate source{row,col} index to be returned.
    for m = 1:length(mat_files)
        load( mat_files{m} );
        display(sprintf('loaded source file %s', mat_files{m}));
        for p = 1:length( mat_parameters{m} )
            for d = 1:2:length( mat_source_map{m,p} )
                r = mat_source_map{m,p}(d);
                c = mat_source_map{m,p}(d+1);
                for n = 1:length(names)
                    try
                        contexts{n}{r,c} = eval( 'context' );
                        contexts{n}{r,c}.parameter = c;
                    catch
                        contexts{n}{r,c} = [];
                    end
                    try
                        try
                            infos{n}{r,c} = eval( sprintf('%s.p%d.info', names{n}, p ) );      
                        catch
                            infos{n}{r,c} = eval( sprintf('p%d.%s_p%d_cdf_info', p, names{n}, p ) ); 
                        end
                    catch
                        display(sprintf('data missing for %s.p%d', names{n}, p ) );
                        infos{n}{r,c} = [];
                        contexts{n}{r,c} = [];
                    end
                    try
                        if infos{n}{r,c}.ergodic
                            try
                                cdfs{n}{r,c} = eval( sprintf('%s.p%d.cdf', names{n}, p ) );
                            catch
                                cdfs{n}{r,c} = eval( sprintf('p%d.%s_p%d_cdf', p, names{n}, p ) );
                            end
                        else
                            cdfs{n}{r,c} = [];
                        end
                    catch
                    end
                end
            end
        end
    end
end