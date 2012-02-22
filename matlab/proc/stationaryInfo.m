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

% this function provides the stationary CDF info for the specified feature
function [ feature, st_info ] = stationaryInfo( feature )

    tic_time = clock();
    
    cache_name = sprintf('%s_%s_r%d_st', feature.name, feature.context.config, feature.context.run );
    rfile = sprintf('%s/ana/r%d/%s_st.mat', feature.context.config, feature.context.run, feature.name );
    
    [ success, st_info, feature.context ] = loadVariable( feature.context, cache_name, rfile );
    
    if ~success || isempty( st_info )
        statenv;
        display(sprintf('searching for steady-state behaviour in %s', cache_name ) );
        [ feature, ts_data ] = timeseriesData( feature );
        
        if timeseriesValid( ts_data )

            start_time = feature.context.tmin;
            end_time = feature.context.tmax;
            
            a = 1;
            trace = [];

            % we process time-series data in reverse order
            [ times, idx ] = sort( ts_data.times, 'descend' );
            values = ts_data.values(idx);

            ts_data.times = ts_data.times(idx);
            ts_data.values = ts_data.values(idx);

            dist_bins = unique( values );

            % abort if there are too few items to satisfy minwindows and
            % minitems

            if length( values )/st_minwindows >= st_minitems

                % the minimum window_width is selected by the first st_minitems
                window_width = end_time-times(st_minitems);
                if isfield( ts_data, 'st_minperiod') && window_width < ts_data.st_minperiod
                    window_width = ts_data.st_minperiod;
                end
                if isfield( ts_data, 'st_minstep' )
                    st_minincrement = ts_data.st_minstep;
                end
                total_windows = length( end_time:-window_width:start_time ) - 1;

                test_start_time = clock();
                test_time = test_start_time;
                output_interval = 60;
                resolutions_tested = 0;
                resolutions_found = 0;

                last_passed = false;

                while isnan(total_windows) || total_windows >= st_minwindows

                    [ window_count, p_value ] = stationaryTest( ts_data, dist_bins, window_width, start_time, end_time );

                    resolutions_tested = resolutions_tested + 1;

                    % the window_width passed stationarity test if it has the
                    % minimum period and number of windows
                    if window_count*window_width > st_mintime && window_count > st_minwindows
                        trace(end+1,:) = [ window_width window_count total_windows p_value ];
                        resolutions_found = resolutions_found + 1;
                        passed = true;
                    else
                        passed = false;
                    end

                    if etime( clock(), test_time ) > output_interval
                        display(sprintf('just tested %dth window width @ %0.3f, found %d possible steady-state periods, searching for %0.3f seconds', resolutions_tested, window_width, resolutions_found, etime( clock(), test_start_time ) ) );
                        test_time = clock();
                    end

                    % even if we find all windows pass keep testing to see if there
                    % are better window widths.

                    if ~passed && ~last_passed
                        % if we failed two times in a row double our step scale
                        a = a + a;
                    elseif passed && ~last_passed
                        % if we passed after failing jump back
                        window_width = window_width - a*st_minincrement;
                        a = 1;
                    elseif ~passed && last_passed
                        % if we failed after passing jump back
                        window_width = window_width - a*st_minincrement;
                        a = 1;
                    elseif passed && last_passed
                        % we passed last time and this time
                        if size( trace, 1 ) > 1
                            t_ss = end_time - trace(:,1).*trace(:,2);
                            if abs( t_ss(end) - t_ss(end-1) ) < 5
                                % if both widths found a start time within 5
                                % seconds of each other jump forward
                                a = a + a;
                            end
                        end
                    end

                    % set the new window width
                    window_width = window_width + a*st_minincrement;
                    total_windows = length( end_time:-window_width:start_time ) - 1;
                    last_passed = passed;
                end

                % no window width was found which passed for all windows and we
                % exausted our possible widths
                if total_windows < st_minwindows
                    % make a best guess using the fitness function Q^SS_p / t^SS_p
                    if size( trace, 1 ) > 0 % make a best guess window_width

                        p_score = end_time - trace(:,1).*trace(:,2);
                        [ p_score order ] = sort( p_score, 'ascend' );

                        p_chosen_alpha = 0;
                        p_chosen = nan;
                        for r = 1:length(order)
                            if trace(order(r),4) > p_chosen_alpha
                                p_chosen = order(r);
                                p_chosen_alpha = trace(order(r),4);
                            end
                            % if we have looked more than 10% of our total period
                            if trace(order(1),1)*trace(order(1),2)-trace(order(r),1)*trace(order(r),2) > (end_time-start_time)*0.1
                                break;
                            end
                        end

                        window_width = trace( p_chosen, 1 );
                        window_count = trace( p_chosen, 2 );

                    else % no window_width found
                        window_width = nan;
                        window_count = nan;
                        p_chosen = -1;
                    end
                end
            else % too few items to test
                window_width = nan;
                window_count = nan;
                p_chosen = -2;
            end

            start_time = nan;
            start_idx = nan;
            stationary = window_width > 0;
            edge_idxs = [];

            if p_chosen > 0
                start_time = end_time - window_width*window_count;

                start_idx = find( times < start_time, 1 ) - 1;
                if isempty( start_idx ) % there was no non-statioary data in the time-series
                    start_idx = length( times );
                end
                edges = start_time:window_width:end_time;
                bucket_counts = histc( times, edges );
                edge_idxs = cumsum( bucket_counts( end-1:-1:1 ) );
            end

            st_info = newStationaryInfo();
            st_info.stationary = stationary; % boolean flag to indicate data passed stationarity
            st_info.start_time = start_time; % time steady-state started 
            st_info.start_idx = start_idx; % index of first measurement after start_time (in reverse order)
            st_info.window_width = window_width; % window width in seconds
            st_info.window_count = window_count; % number of windows
            st_info.edge_idxs = edge_idxs; % left-most edge index (in reverse order) for window boundaries
            st_info.trace = trace; % trace information about stationarity test [width similar total]
            if p_chosen > 0
                st_info.chosen_width = p_chosen;
            else
                st_info.failure_code = p_chosen;
            end
            
            st_info.('walltime') = etime( clock(), tic_time );
            st_info.('dirty') = true;
            st_info.('persist') = true;
            feature.context = saveVariable( feature.context, st_info, cache_name, rfile );
        end
    end
    
end