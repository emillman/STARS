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

% this function determines if the specified feature is valid
function [ valid ] = featureValid( feature )

    valid = true;
    
    % features must be matlab structs.
    if ~isstruct( feature )
        valid = false;
    end
    
    if valid && ~(isfield( feature, 'name' ) && isvarname( feature.name ))
        display('features must have a name and it must be a valid matlab variable');
        valid = false;
    end
    
    if valid && ~(isfield(feature,'func') && ischar( feature.func ) )
        display('feature function must be a character array');
        valid = false;
    end
    
    if valid && ~(isfield(feature,'pars') && ( isempty(feature.pars) || iscell(feature.pars) ) )
        display('feature function parameters must be empty or a cell');
        valid = false;
    end
    
    if valid && ~(isfield(feature,'stats') && iscell( feature.stats) )
        display('feature statistics must be a cell array');
        valid = false;
    end

    if valid && ~(isfield(feature,'title') && ischar(feature.title))
        display('feature title must be a character array');
        valid = false;
    end
    
    if valid && ~(isfield(feature,'units') && ischar(feature.units))
        display('feature units must be a character array');
        valid = false;
    end
end