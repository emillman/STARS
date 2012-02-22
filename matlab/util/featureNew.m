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

% this file creates a new feature to be processed by the analysis engine
% it creates a struct() containing the required parameters

function [ feature ] = featureNew( name, func, pars, stats, title, units )

    % create the struct
    fields = {'name','func','pars','stats','title','units'};
    values = { name, func, pars, stats, title, units };
    % we use this instead of struct() because fields that are cell arrays
    % will create struct arrays.
    feature = cell2struct( values, fields, 2 );
    
    % test that the feature is valid, otherwise return a blank feature.
    if ~featureValid( feature )
        warning('analysis:featureNew','feature is invalid and cannot be created.');
        feature = {};
    end

end