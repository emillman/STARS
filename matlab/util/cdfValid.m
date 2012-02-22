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

% this function determines if the specified cdf data is valid
function [ valid ] = cdfValid( cdf )

    valid = true;
    
    if ~isstruct( cdf )
        valid = false;
    end
    
    if valid && ...
            ~( isfield( cdf, 'prob' ) && ...
               isfield( cdf, 'bins' ) && ...
               isfield( cdf, 'log_prob' ) && ...
               isfield( cdf, 'log_bins' ) && ...
               size( cdf.prob, 2 ) == 1 && ...
               size( cdf.prob, 1) == size( cdf.bins, 1) )
          valid = false;
    end

end