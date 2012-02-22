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

% this function performs a stationary search of the time-series data
% TIME SERIES DATA MUST BE IN REVERSE ORDER!
function [ window_count, p_value ] ... % the number of windows which passed the test. 1 - none
    = stationaryTest( ts_data, ... % time-seres strut in reverse order
    dist_bins, ... % the bins to use when calculating the cdf
    window_width, ... % the window width in seconds to use
    start_time, ... % earliest time to consider when testing
    end_time ) % latest time to consider when testing
    statenv;

    p_value = 0;
    
    if ts_data.times(1) < ts_data.times(end)
        error('analysis:stationaryTest','time-series data is not in reverse order');
    end
    edges = start_time:window_width:end_time;
    %edges = end_time:-window_width:start_time;
    window_count = 1;
    cdf_sum = zeros( size( dist_bins ) );
    
    times = ts_data.times;
    values = ts_data.values;

    % pre-calculate number of items in each bucket for performance reasons
    hi = 0;
    bucket_counts = histc( times, edges );
    bucket_counts = bucket_counts(end-1:-1:1);
    
    for b = 1:length( bucket_counts )

        lo = hi+1;
        hi = lo + bucket_counts(b) - 1;

        if (hi-lo+1) < st_minitems % abort if fewer than required sampled exist
            break;
        end
        if b == 1 % prime estimated CDF with first bucket
            cdf_sum = histc( values(lo:hi), dist_bins );
            cdf_sum = cumsum(cdf_sum)./sum(cdf_sum);
            continue;
        end

        % test data in values((offset+lo):(offset+hi)) range
        cdf = histc( values(lo:hi), dist_bins );
        cdf = cumsum(cdf)./sum(cdf);
        %calculate the estimated cdf and increment with current
        %cdf
        cdf_est = cdf_sum / (b - 1);
        cdf_sum = cdf_sum + cdf;

        % assign success if the kstest passes on the last
        % bucket
        [ H, new_p_value ] = kstest2CDF( cdf, hi-lo+1, cdf_est, lo-1, st_alpha );
        if H == 0
            p_value = new_p_value;
            window_count = window_count + 1;
            if b == length( bucket_counts )
                break; % window_width is completely stationary
            end
        else
            if b == 1
                p_value = new_p_value;
            end
            break; % test failed break out of current window_width
        end

    end

end