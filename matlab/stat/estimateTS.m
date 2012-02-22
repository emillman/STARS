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

% this function produces time-series estimates for the specified data and
% statistics
function [ estimates ] = estimateTS( ts_set, stats )
    statenv;

    estimates = {};
     
    bucket_set = cell( length( stats ), 1 );
    idx = 0;
    for i = 1:length( ts_set )
        if ~isempty( ts_set{i} ) && ~isempty( ts_set{i}.times );
            idx = i;
            break;
        end
    end
    
    if idx > 0
        buckets = nan( size( ts_set{idx}.times, 1 ), length( stats ) );
        for i = 1:length( bucket_set )
            bucket_set{i} = nan( size( buckets, 1 ), length( ts_set ) );
        end
        bucket_counts = nan( size( ts_set{idx}.times, 1 ), length( ts_set ) );

        for i = 1:length( ts_set )
            bucket_counts(:,i) = ts_set{i}.counts;
            for j = 1:length( stats )
                bucket_set{j}(:,i) = ts_set{i}.values(:,j);
            end
        end

        stat_names = cell( size( stats ) );

        for i = 1:length( stats )
            switch stats{i}(2)
                case STAT_MEAN
                    buckets(:,i) = mean( bucket_set{i}, 2 );
                    stat_names{i} = sprintf( 'mean-%s', ts_set{idx}.stat_names{i} );
                case STAT_MEDIAN
                    buckets(:,i) = median( bucket_set{i}, 2 );
                    stat_names{i} = sprintf( 'median-%s', ts_set{idx}.stat_names{i} );
                case STAT_STD
                    buckets(:,i) = std( bucket_set{i}, 0, 2 );
                    stat_names{i} = sprintf( 'std-%s', ts_set{idx}.stat_names{i} );
                case STAT_VAR
                    buckets(:,i) = var( bucket_set{i}, 0, 2 );
                    stat_names{i} = sprintf( 'var-%s', ts_set{idx}.stat_names{i} );
                case STAT_SUM
                    buckets(:,i) = sum( bucket_set{i}, 2 );
                    stat_names{i} = sprintf( 'sum-%s', ts_set{idx}.stat_names{i} );
                case STAT_COUNT
                    buckets(:,i) = size( bucket_set{i}, 2 );
                    stat_names{i} = sprintf( 'count-%s', ts_set{idx}.stat_names{i} );
                case STAT_MAX
                    buckets(:,i) = max( bucket_set{i}, [], 2 );
                    stat_names{i} = sprintf( 'max-%s', ts_set{idx}.stat_names{i} );
                case STAT_MIN
                    buckets(:,i) = min( bucket_set{i}, [], 2 );
                    stat_names{i} = sprintf( 'min-%s', ts_set{idx}.stat_names{i} );
                case STAT_SKEW
                    buckets(:,i) = my_skewness( double(bucket_set{i}), [], 2 );
                    stat_names{i} = sprintf( 'skew-%s', ts_set{1}.stat_names{i} );
            end
        end
        
        estimates = struct('times',ts_set{1}.times,'values',buckets,'counts',bucket_counts, ...
        'title', ts_set{idx}.title, 'units', ts_set{idx}.units );
        estimates.('stat_names') = stat_names;
    else
        estimates = struct('times',[],'values',[],'counts',[], ...
        'title', 'empty', 'units', 'empty' );
        estimates.('stat_names') = {};
    end

end