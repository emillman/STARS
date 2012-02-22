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

function [ success, ... % true if field data was loaded, false otherwise
    field ] = ... % contains the array of values if successful, can be data types other than double
    loadRawField( file, ... % file containing the raw data field values
    key ) % optional - key for which values to load data(key)
    
    assert( ~isempty( file ), 'file must be specified' );
    if ~isempty( whos('key') )
        assert( isempty( key ) || islogical( key ), 'key must be a logical vector if it is specified' );
    else
        key = [];
    end

    success = false;
    field = [];
    fid = 0;

    try
        fid = fopen( file );
        if fid > 0
            % read in the format code and then the rest of the file
            format = fread(fid,1,'int8');
            if ~isempty( format )
                switch format
                    case -8
                        format = '*float64';
                    case 8
                        format = '*int64';
                    case 18
                        format = '*uint64';
                    case -4
                        format = '*float32';
                    case 4
                        format = '*int32';
                    case 14
                        format = '*uint32';
                    case 2
                        format = '*int16';
                    case 12
                        format = '*uint16';
                    case 1
                        format = '*int8';
                    case 11
                        format = '*uint8';
                    otherwise
                        error('STARS:loadRawField','read unknown format code for %s', file );
                end
            end
            field = fread(fid,format);
            if ~isempty( key )
                if length( key ) == length( field )
                    field = field(key);
                else
                    error('STARS:loadRawField','key parameter was different length than field: %d ~= %d', length( key ), length( field ) );
                end
            end
            success = true;
            
            fclose( fid );
        end

    % any failure encountered when loading the field from file is a crash
    % condition, but make sure the file is closed before continuing.
    catch me
        try
            if fid > 0
                fclose( fid );
            end
        catch
        end
        rethrow( me );
    end

end