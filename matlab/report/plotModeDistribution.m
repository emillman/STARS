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

function [] = plotModeDistribution( cdf, info, linespec, plot_cdf, max_modes, min_samples )

    assert( isstruct( cdf ), 'cdf data must be a struct' );
    assert( isfield( cdf, 'bins' ), 'cdf data must have bins field' );
    assert( isfield( cdf, 'cdfs' ), 'cdf data must have cdfs field' );
    
    if isempty( whos('plot_cdf') )
        min_samples = true;
    end
    if isempty( whos('max_modes' ) )
        max_modes = info.modes;
    end
    if isempty( whos('min_samples') )
        min_samples = 0;
    end

    for d = 1:min( length( cdf.bins ), max_modes ) 
        if info.mode_sizes(d) < min_samples
            continue;
        end
        if plot_cdf
            plot( cdf.bins{d}, cdf.cdfs{d}, linespec, 'LineWidth', 1 );
        else
            plot( cdf.bins{d}, cdf2pdf( cdf.cdfs{d}, cdf.bins{d} ), linespec, 'LineWidth', 1 );
        end
    end
    
    title( cdf.title );
    xlabel( cdf.units );
    ylabel('probability');
    
end