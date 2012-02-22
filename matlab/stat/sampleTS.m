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

% this function produces time-series samples for the specified data and
% statistics
function [ samples, period ] = sampleTS( ts_data, stats, period, start_time, end_time )
    statenv;

    samples = {};
    
    idx = ts_data.times >= start_time & ts_data.times < end_time;
    ts_data.times = ts_data.times(idx);
    ts_data.values = ts_data.values(idx);
    
    if period > (end_time-start_time)
        period = end_time-start_time;
    else
        period = (end_time-start_time)/floor( (end_time-start_time)/period );
        if sum( ts_data.times < period ) == 0
            period = period + 1e-15;
        end
    end
    
    edges = start_time:period:end_time;
    bucket_counts = histc( ts_data.times, edges );
    bucket_counts = bucket_counts(1:end-1);
    buckets = nan( length(bucket_counts), length(stats) );
    times = nan( size( bucket_counts ) );
    
    stat_names = cell( size( stats ) );
    for j = 1:size(buckets,2)
        switch stats{j}(1)
            case STAT_MEAN
                stat_names{j} = 'mean';
            case STAT_MEDIAN
                stat_names{j} = 'median';
            case STAT_STD
                stat_names{j} = 'std';
            case STAT_VAR
                stat_names{j} = 'var';
            case STAT_PSEC
                stat_names{j} = 'per sec';
            case STAT_CSEC
                stat_names{j} = 'count per sec';
            case STAT_SUM
                stat_names{j} = 'sum';
            case STAT_COUNT
                stat_names{j} = 'count';
            case STAT_MIN
                stat_names{j} = 'min';
            case STAT_MAX
                stat_names{j} = 'max';
            case STAT_SKEW
                stat_names{j} = 'skew';
        end
    end
    
    if length( stats ) == 1
        [buckets times] = sampleTS2( ts_data, stats, times, edges, buckets, bucket_counts );
    else
        [buckets times] = sampleTS3( ts_data, stats, times, edges, buckets, bucket_counts );
    end
    
    % we are sampling time-series data for estimation
    if isfield(ts_data,'title')
        samples = struct('times',times,'values',buckets,'counts',bucket_counts, ...
            'title', ts_data.title, 'units', ts_data.units );
        samples = setfield( samples, 'stat_names', stat_names );
    % we are constant rate sampling to generate time-series data
    else
        samples = struct('times',times,'values',buckets );
    end
    
end

function [ buckets, times ] = sampleTS2( ts_data, stats, times, edges, buckets, bucket_counts )
    statenv;
    test = stats{1}(1);
    hi =0;
    if test == STAT_PSEC
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data/period;
            else
                buckets(i,1) = sum( data )/period;
            end
        end
    elseif test == STAT_CSEC
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            if hi-lo == 0
                buckets(i,1) = 1/period;
            else
                buckets(i,1) = (hi-lo+1)/period;
            end
        end
    elseif test == STAT_MEAN
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data;
            else
                buckets(i,1) = mean( data );
            end
        end
    elseif test == STAT_MEDIAN
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data;
            else
                buckets(i,1) = median( data );
            end
        end
    elseif test == STAT_STD
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            if hi-lo == 0
                buckets(i,1) = 0;
            else
                buckets(i,1) = std( ts_data.values(lo:hi) );
            end
        end
    elseif test == STAT_VAR
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            if hi-lo == 0
                buckets(i,1) = 0;
            else
                buckets(i,1) = var( ts_data.values(lo:hi) );
            end
        end
    elseif test == STAT_SUM
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data;
            else
                buckets(i,1) = sum( data );
            end
        end
    elseif test == STAT_COUNT
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            buckets(i,1) = hi-lo+1;
        end
    elseif test == STAT_MIN
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data;
            else
                buckets(i,1) = min( data );
            end
        end
    elseif test == STAT_MAX
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            data = ts_data.values(lo:hi);
            if hi-lo == 0
                buckets(i,1) = data;
            else
                buckets(i,1) = max( data );
            end
        end
    elseif test == STAT_SKEW
        for i = 1:size(buckets,1)
            lo = hi + 1;
            hi = lo + bucket_counts(i)-1;

            period = edges(i+1)-edges(i);
            times(i) = period/2 + edges(i);

            if hi-lo == 0
                buckets(i,1) = nan;
            else
                buckets(i,1) = my_skewness( double(ts_data.values(lo:hi)) );
            end
        end
    end
end

function [ buckets, times ] = sampleTS3( ts_data, stats, times, edges, buckets, bucket_counts )
    statenv;
    
    hi = 0;
    for i = 1:size(buckets,1)
        lo = hi + 1;
        hi = lo + bucket_counts(i)-1;

        period = edges(i+1)-edges(i);
        times(i) = period/2 + edges(i);

        data = ts_data.values(lo:hi);
        data_len = hi-lo+1;

        for j = 1:size(buckets,2)
            test = stats{j}(1);
            if data_len > 1
                if test == STAT_PSEC
                    buckets(i,j) = sum( data )/period;
                elseif test == STAT_CSEC
                    buckets(i,j) = data_len/period;
                elseif test == STAT_MEAN
                    buckets(i,j) = mean( data );
                elseif test == STAT_MEDIAN
                    buckets(i,j) = median( data );
                elseif test == STAT_SKEW
                    buckets(i,j) = my_skewness( double(data) );
                elseif test == STAT_STD
                    buckets(i,j) = std( data );
                elseif test == STAT_VAR
                    buckets(i,j) = var( data );
                elseif test == STAT_SUM
                    buckets(i,j) = sum( data );
                elseif test == STAT_COUNT
                    buckets(i,j) = hi-lo+1;
                elseif test == STAT_MIN
                    buckets(i,j) = min( data );
                elseif test == STAT_MAX
                    buckets(i,j) = max( data );
                end
            elseif data_len == 1
                if test == STAT_PSEC
                    buckets(i,j) = data/period;
                elseif test == STAT_CSEC
                    buckets(i,j) = 1/period;
                elseif test == STAT_MEAN
                    buckets(i,j) = data;
                elseif test == STAT_MEDIAN
                    buckets(i,j) = data;
                elseif test == STAT_SKEW
                    buckets(i,j) = nan;
                elseif test == STAT_STD
                    buckets(i,j) = 0;
                elseif test == STAT_VAR
                    buckets(i,j) = 0;
                elseif test == STAT_SUM
                    buckets(i,j) = data;
                elseif test == STAT_COUNT
                    buckets(i,j) = 1;
                elseif test == STAT_MIN
                    buckets(i,j) = data;
                elseif test == STAT_MAX
                    buckets(i,j) = data;
                end
            else
                buckets(i,j) = nan;
            end
        end
    end
end