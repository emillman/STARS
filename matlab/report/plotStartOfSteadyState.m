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

function [] = plotStartOfSteadyState( context, info, par, varargin )

    cdf = info.st_start_times( ~isnan(info.st_start_times));
    cdf_bins = unique( cdf );
    if length( cdf_bins ) > 1
        cdf = hist( cdf, cdf_bins );
        cdf = cumsum( cdf )/sum( cdf );
    elseif ~isempty(cdf)
        cdf = 1;
    end

    if isempty( varargin )
        linespec = '-b';
    else
        linespec = varargin{1};
    end

    if par == 0
        plot( cdf_bins, cdf, linespec );
        axis( [ context.tmin context.tmax 0 1 ] );
        ylabel('probability of transient phase over');
        view(0,0);
    else
        plot3( cdf_bins, par.*ones( size( cdf_bins ) ), cdf, linespec );
        axis( [ context.tmin context.tmax -1 par+1 0 1 ] );
        ylabel('scenario');
        zlabel('probability of transient phase over');
        view(45,45);
    end

    title('Start Time of Steady-State Behaviour')
    xlabel('seconds');
   
    
end