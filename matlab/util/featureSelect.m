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

function [ features ] = featureSelect( features, prefix )
    feature_count = length( features );
    for f = feature_count:-1:1
        drop = false;
        if length( features{f}.func ) < length( prefix )
            drop = true;
        elseif ~strncmp( features{f}.func, prefix, length( prefix ) )
            drop = true;
        end
        if drop
            features = features( [ 1:f-1 f+1:end ]);
        end
    end