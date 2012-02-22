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

function [ pdf, pdf_bins ] = cdf2pdf( cdf, bins )
% transform the cdf to a pdf

    if ~isempty( cdf ) && ~isempty( bins )
        cdf = cdf(:);
        bins = bins(:);

        if cdf(end) - 1 > 1e-15
            error('cdf failed to pass end=1 requirement');
        end

        if length( cdf ) == 1
            pdf_bins = bins;
            pdf = cdf;
        else
            delta = cdf - [0; cdf(1:end-1)];
            pdf_bins = bins;
            pdf = delta;
        end
    else
        pdf = [];
        pdf_bins = [];
    end

end