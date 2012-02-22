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

% this file is called after each parameter is analyzed
% it looks at the parameter results generated and determines if more runs,
% or samples, are needed.

% this is the default script which simply requires that all max_repeats
% samples have been tested. If they have not the number of additional
% samples to generate is written to the file <config>_p<#>.dat.

function [ rcode, context ] = analysisControl( context, features )

    % initialize return status to error
    % 0 - success
    % 1 - unknown error
    % 2 - unable to write file
    rcode = 1;
    % initialize number of additional runs to perform to 0
    more_runs = context.max_repeat - context.repeat;
    
    % if more samples are required write the number to the file
    % <config>_p<#>.dat
    if more_runs > 0
        file = sprintf( '%s_p%d.dat', context.config, context.parameter );
        fid = fopen( file, 'w' );
        if fid ~= -1
            fprintf( fid,'%d', round(more_runs) );
            fclose( fid );
            rcode = 0;
        else
            rcode = 2;
        end
    else
        rcode = 0;
    end
end