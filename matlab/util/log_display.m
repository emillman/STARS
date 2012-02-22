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

% this script logs display test to file to avoid large amounts of useless
% text when generating reports.

% the context.log_file field MUST be declared for this function to run as
% expected.

function [ context ] = log_display( context, string )
    
    if ~isfield( context, 'log_file_identifier' );
        if ~isfield( context, 'log_file' )
            context.('log_file') = 'analysis.log';
        end
        context.('log_file_identifier') = fopen( context.log_file, 'a' );
    end
    
    string = sprintf( '%s\r\n', string );
    fwrite( context.log_file_identifier, string );
    
end