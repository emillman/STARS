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

function [ H, pValue ] = kstest2CDF( x1, n1, x2, n2, alpha )
    kss = max( abs(x1 - x2) );

    % from kstest2.m matlab source

    n      =  n1 * n2 /(n1 + n2);
    lambda =  max((sqrt(n) + 0.12 + 0.11/sqrt(n)) * kss , 0);
    k       =  (1:101)';
    pValue  =  2 * sum((-1).^(k-1).*exp(-2*lambda*lambda*k.^2));
    pValue  =  min(max(pValue, 0), 1);
    H  =  (alpha >= pValue);
end