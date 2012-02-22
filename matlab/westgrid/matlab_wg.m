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

% this script acts as a bootstrap for the analysis engine when running on
% westgrid.

function [ rcode ] = matlab_wg( process_name, script_file, root )
    rcode = 1;
    
    diary( [root filesep script_file '.log'] );
    
    try
        process_name
        script_file
        root

        % change current working directory to the remoteMatlabLocation
        % specified in the matlab_orcinus.m file
        eval( sprintf('cd %s', root ) ); 
        
        pwd
        
        % setup the path needed for the engine
        addpath(genpath('matlab'),0);

        path

        % call the process_name
        % usually analyzePatameter or combineParameters
        func = str2func( process_name );
        rcode = func( script_file );
        
    catch me
        % barf out any unhandled exceptions from the engine and exit
        if isempty( whos('process_name') )
            process_name = 'error: not defined';
        end
        if isempty( whos('script_file') )
            script_file = 'error: not defined';
        end
        if isempty( whos('root') )
            root = 'error: not defined';
        end
        context = struct('process_name',process_name,'script_file',script_file,'root',root);
        log_crashInfo( me, context );
        rcode = 1;
    end
    rcode
    diary off;
    if ~(rcode == 0)
        % exit with an error code if the job did not complete successfully
        exit( rcode );
    end
end