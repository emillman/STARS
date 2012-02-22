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


function [] = tableFeatureResults( features, infos, cdfs, min_samples )

    display('\begin{table}');
    display('\caption{caption}');
    display('\tabl{label}');
    display('\begin{center}');
    display('\begin{tabular}{ | l | c | c | c | c | }');
    display('\hline');
    display('\textbf{Feature} & \textbf{Min} & \textbf{Mean} & \textbf{Median} & \textbf{Max} \\' );
    display('\hline');
    for n = 1:length( features )

        display(sprintf('\\multirow{%d}{*}{\\textbf{%d) %s}}', size( infos{n}, 2 ), n, features{n} ));
        
        for c = 1:size( infos{n}, 2 )
            min_value = '-';
            mean_value = '-';
            median_value = '-';
            max_value = '-';
            if ~isempty( infos{n}{1,c} ) && infos{n}{1,c}.ergodic && infos{n}{1,c}.mode_sizes(1) >= min_samples
                
                cdf = cdfs{n}{1,c}.cdfs{1};
                bins = cdfs{n}{1,c}.bins{1};
                
                min_value = sprintf('%E', bins(1) );
                max_value = sprintf('%E', bins(end) );
                
                mean_idx = find( cdf >= 0.5, 1 );        
                if mean_idx > 1
                    yy = double(bins( mean_idx-1:mean_idx ));
                    xx = double(cdf( mean_idx-1:mean_idx ));
                    mean_value = polyval( polyfit( xx, yy, 1 ), 0.5 );
                else
                    mean_value = bins( mean_idx );
                end
                mean_value = sprintf('%E', mean_value );
                
                if mod( length( bins ), 2 ) % odd
                    median_value = bins( floor( length( bins )/2 )+1 );
                else
                    median_value = (bins( floor( length( bins )/2 ) ) + bins( floor( length( bins )/2 )+1 )) / 2;
                end
                median_value = sprintf('%E', median_value );

            end
            display( sprintf( '& $%s$& $%s$& $%s$& $%s$ \\\\', min_value, mean_value, median_value, max_value ) );
        end
        display('\hline');
    end

    display('\end{tabular}');
    display('\end{center}');
    display('\end{table}');
end