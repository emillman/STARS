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

% this script plots the mean of the largest mode for the set of features
% provided on one figure.

function [ plotted_data ] = plotSummaryReport( infos, cdfs, linespec, min_samples )
    plotted_data = false;
    data_points_y = nan( size( cdfs ) );
    data_points_x = 1:size( cdfs, 2 );
    
    for c = 1:size( cdfs, 2 )
        
        if infos{c}.ergodic && infos{c}.mode_sizes(1) >= min_samples
            
            cdf = cdfs{c}.cdfs{1};
            bins = cdfs{c}.bins{1};
            
            mean_idx = find( cdf >= 0.5, 1 );        
            if mean_idx > 1
                yy = double(bins( mean_idx-1:mean_idx ));
                xx = double(cdf( mean_idx-1:mean_idx ));
                mean_value = polyval( polyfit( xx, yy, 1 ), 0.5 );
            else
                mean_value = bins( mean_idx );
            end
            
            data_points_y(c) = mean_value;
        end
    end
    
    data_points_x( isnan( data_points_y ) ) = [];
    data_points_y( isnan( data_points_y ) ) = [];
    
    if ~isempty( data_points_x )
        plot( data_points_x, data_points_y, linespec, 'MarkerSize', 10 );
        plotted_data = true;
    end
    
end