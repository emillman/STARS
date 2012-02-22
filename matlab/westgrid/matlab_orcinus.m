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

% this function submits matlab jobs to WestGrid's Orcinus cluster
% to make use up to 64 MDCE licenses concurrently.

% format for config_list is { {'name',[pars],'template'}, ... }

function [] = matlab_orcinus( config_list, ... % cell-array of experiments to analyze
    combine, ... % produce combined output results for all parameters analyzed
    username, ... % username on orcinus cluster
    email, ... % email to receive job notification emails (bae)
    remoteLocation, ... % location on orcinus where the matlab folder is to be found, temp files are placed in data
    procs, ... % number of processes to use for analysis, if combine then procs = 1, 
    ram, ... % amount of ram to use per process, 1234mb , should be higher than context.cache.limit_bytes
    walltime, ... % maximum time to let job run, hh:mm:ss format
    dev ) % utilize the development queue, small jobs only

    assert( ~isempty( config_list ), 'list of experiments to analyze must be provided' );
    assert( islogical( combine ) && length( combine ) == 1, 'combine must be true/false' );
    assert( ~isempty( username) && ischar( username ), 'username must be a character array' );
    assert( ~isempty( email ) && ischar( email ), 'email must be a character array' );
    assert( ~isempty( remoteLocation ) && ischar( remoteLocation ), 'remoteLocation must be a character array: /global/scratch/username/stars' );
    assert( procs > 0 && procs <=64, 'procs must be in range: [1,64]' );
    assert( ~isempty( ram ) && ischar( ram ), 'ram must be a character array: 1024mb' );
    assert( ~isempty( walltime ) && ischar( walltime ), 'walltime must be a character array: HH:MM:SS' );
    assert( islogical( dev ) && length( dev ) == 1, 'dev must be true/false' );
    
    clusterHost = sprintf('%s@orcinus.westgrid.ca', username );

    remoteDataLocation = sprintf('%s/data', remoteLocation );

    for s = 1:length(config_list)
        config = config_list{s}{1};
        pars = config_list{s}{2};
        template = config_list{s}{3};
        if ~combine
            for p = 1:length(pars)
                script_name = sprintf( '%s_%d', config, pars(p) );
                fid = -1;
                try
                    fid = fopen( [template '.m'], 'r' );
                    template_text = fread( fid, '*char' );
                    fclose( fid );
                    template_text = sprintf('%s\r\ncontext.config=\''%s\'';\r\ncontext.parameter=%d;\r\ncontext.parameters=%d;\r\ncontext.cpu=%d;', ...
                        template_text, config, pars(p), max( pars ), procs-1 );
                    fid = fopen( [ script_name '.m' ], 'w' );
                    fwrite( fid, template_text );
                    fclose( fid );
                catch me
                    if fid > 0
                        fclose( fid );
                    end
                    rethrow( me );
                end
                
                display(sprintf('Submitting Analysis Job for %s parameter %d', config, pars(p) ) );
                if procs > 1
                    submitParforJob( clusterHost, email, remoteDataLocation, remoteLocation, ram, walltime, procs, dev, script_name, 'parfor_analyzeParameter' );
                else
                    submitSerialJob( clusterHost, email, remoteDataLocation, remoteLocation, ram, walltime, procs, dev, script_name, 'analyzeParameter' );
                end
            end
        else
            script_name = sprintf( '%s', config );
            fid = -1;
            try
                fid = fopen( [template '.m'], 'r' );
                template_text = fread( fid, '*char' );
                fclose( fid );
                template_text = sprintf('%s\r\ncontext.config=\''%s\'';\r\ncontext.parameter=%d;\r\ncontext.parameters=%d;\r\ncontext.cpu=%d;', ...
                    template_text, config, 0, max( pars ), procs-1 );
                fid = fopen( [ script_name '.m' ], 'w' );
                fwrite( fid, template_text );
                fclose( fid );
            catch me
                if fid > 0
                    fclose( fid );
                end
                rethrow( me );
            end
                
            display(sprintf('Submitting Combine Job for %s', config ) );
            submitSerialJob( clusterHost, email, remoteDataLocation, remoteLocation, ram, walltime, 1, dev, script_name, 'combineParameters' );
        end
    end
end