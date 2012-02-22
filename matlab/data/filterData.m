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

function [ feature, data ] = filterData( feature, data, column, select )

    if ~isempty(select)
        if isempty( data )
            [ feature, data ] = loadRawData( feature , column );
            key = data{column} == select(1);
            for f = 2:length( select )
                key = key | data{column} == select(f);
            end
            data = key;
        else
            if length(data) < column || isempty( data{column} )
                [ feature, new_data ] = loadRawData( feature , column );
                data{column} = new_data{column};
                clear new_data;
            end
            
            key = data{column} == select(1);
            
            for f = 2:length( select )
                key = key | data{column} == select(f);
            end
            data{column} = [];
            for c = 1:length(data)
                if ~isempty(data{c})
                    data{c} = data{c}(key);
                end
            end
        end
    end
end