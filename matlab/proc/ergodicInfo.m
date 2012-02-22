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

% this function provides the ergodic CDF information for the specified feature
function [ feature, et_info ] = ergodicInfo( feature )

    tic_time = clock();
    
    cache_name = sprintf('%s_%s_p%d_info', feature.name, feature.context.config, feature.context.parameter );
    rfile = sprintf('%s/ana/p%d/%s_info.mat', feature.context.config, feature.context.parameter, feature.name );

    [ success, et_info, feature.context ] = loadVariable( feature.context, cache_name, rfile );
    % load or resume creation of ergodicity data
    if ~success || ~isstruct( et_info ) || size( et_info.trace, 1 ) < feature.context.repeat
        statenv;
        et_pairs = nan( feature.context.repeat );
        et_pvalues = nan( feature.context.repeat );
        if ~isstruct( et_info )
            display(sprintf('identifying ergodic sets for %s', cache_name ) );
        else
            if size( et_info.trace, 1 ) < feature.context.repeat
                tmp = size( et_info.trace, 1 );
                et_pairs(1:tmp,1:tmp) = et_info.trace;
                et_pvalues(1:tmp,1:tmp) = et_info.pvalues;
                for i = 1:tmp
                    % need to finish up tests for previous runs
                    % or skip known to fail tests
                    if et_pairs(i,i) == 1
                        et_pairs(i,i) = nan;
                    elseif et_pairs(i,i) == 0
                        et_pairs(i,:) = 0;
                        et_pairs(:,i) = 0;
                    end
                end
                display(sprintf('resuming ergodic sets identification for %s', cache_name ) );
            end
            clear info;
        end
        st_periods = nan( feature.context.repeat, 1 );
        st_start_times = nan( feature.context.repeat, 1 );
        st_window_widths = nan( feature.context.repeat, 1 );
        st_window_counts = nan( feature.context.repeat, 1 );
        st_failure_codes = nan( feature.context.repeat, 1 );
        ts_measurement_counts = nan( feature.context.repeat, 1 );
        
        % this is a pair-wise comparison of all samples to improve 
        % performance for the n(n-1) step process samples are marked
        % as stationary or non-stationary to exclude or include them in
        % further comparison. thus as the data becomes less stationary the
        % ergodicity test becomes quicker
        test_time = clock();
        start_time = test_time;
        update_interval = 30;
        for i = 1:feature.context.repeat
            % we can resume existing work check if the sample has been
            % tested for ergodicity already
            if isnan(et_pairs(i,i)) % un-checked sample
                
                % update the context and
                feature.context.('run') = feature.context.runs(i);
                
                [ feature, ts_info1 ] = timeseriesInfo( feature );
                if isstruct( ts_info1 )
                    ts_measurement_counts(i) = ts_info1.size;
                end
                
                % check to make sure the sample is stationary before
                % testing
                
                [ feature, st_info1 ] = stationaryInfo( feature );
                if isstruct( st_info1 ) && st_info1.stationary
                        
                    [ feature, ts_data1 ] = timeseriesData( feature );
                    if timeseriesValid( ts_data1 )

                        ts_data1 = timeseriesReverse( ts_data1 );
                        values1 = ts_data1.values(1:st_info1.start_idx);
                        n1 = length( values1 );
                        unique1 = unique( ts_data1.values(1:st_info1.start_idx) );
                        
                        % compare the stationary sample with all other
                        % samples
                        for j = i+1:feature.context.repeat
                            
                            % skip samples we have already tested
                            if isnan( et_pairs(i,j) ) % untested pair
                                
                                % update context and check to make sure the
                                % sample is stationary
                                feature.context.('run') = feature.context.runs(j);
                                
                                [ feature, st_info2 ] = stationaryInfo( feature );
                                if isstruct( st_info2 ) && st_info2.stationary
                                    
                                    [ feature, ts_data2] = timeseriesData( feature );
                                    if timeseriesValid( ts_data2 )

                                        ts_data2 = timeseriesReverse( ts_data2 );
                                        values2 = ts_data2.values(1:st_info2.start_idx);
                                        n2 = length( values2 );
                                        bins = unique( [unique1; ts_data2.values(1:st_info2.start_idx)] );
                                        
                                        % test the ergodicity of the two
                                        % empirical distributions and
                                        % record the statistical similarity
                                        % information

                                        cdf1 = makeCDF( values1, bins, st_info1 );
                                        cdf2 = makeCDF( values2, bins, st_info2 );

                                        [ p, pval ] = kstest2CDF( cdf1, n1, cdf2, n2, et_alpha );

                                        et_pairs(i,j) = p;
                                        et_pairs(j,i) = et_pairs(i,j);
                                        et_pvalues(i,j) = pval;
                                        et_pvalues(j,i) = et_pvalues(i,j);
                                    else
                                        et_pairs(j,:) = -2; % no sample
                                        et_pairs(:,j) = -2;
                                    end
                                else
                                    % record information about sample which
                                    % was non-stationary
                                    if ~isstruct( st_info2 )
                                        st_failure_codes(j) = -3;
                                    else
                                        st_failure_codes(j) = st_info2.failure_code;
                                    end
                                    et_pairs(j,:) = -1; % sample is not stationary
                                    et_pairs(:,j) = -1;
                                end
                            end
                            if etime( clock(), test_time ) > update_interval
                                percent_complete = 100*((i-1)*feature.context.repeat+j)/(feature.context.repeat*(feature.context.repeat-1));
                                display(sprintf('finished %0.3f%% of tests in %0.3f seconds',percent_complete, etime( clock(), start_time ) ) );
                                test_time = clock();
                            end
                        end
                        
                        % record information about sample which was
                        % stationary
                        et_pairs(i,i) = 1;
                        st_periods(i) = st_info1.window_width*st_info1.window_count;
                        st_start_times(i) = st_info1.start_time;
                        st_window_widths(i) = st_info1.window_width;
                        st_window_counts(i) = st_info1.window_count;
                        %st_failure_codes(i) = st_info1.failure_code;
                    else
                        et_pairs(i,:) = -2; % no sample
                        et_pairs(:,i) = -2;
                    end
                else
                    % record information about sample which was
                    % non-stationary
                    if ~isstruct( st_info1 )
                        st_failure_codes(i) = -3;
                    else
                        st_failure_codes(i) = st_info1.failure_code;
                    end
                    et_pairs(i,:) = -1; % sample is not stationary
                    et_pairs(:,i) = -1;
                end
            end
        end
        
        [ modes, ranks, sizes ] = getErgodicModes( et_pvalues > et_alpha );
        
        % gather information about the modes detected
        times = nan(1,length( modes ));
        min_alphas = nan( size( times ) );
        max_alphas = nan( size( times ) );
        mean_alphas = nan( size( times ) );
        ergodic_samples = zeros( size( times ) );
        for m = 1:length( modes )
            times(m) = max( st_start_times( modes{m} ) );
            alpha_sum = 0;
            ergodic_samples( modes{m} ) = 1;
            for s = 1:length( modes{m} )
                alphas = et_pvalues( modes{m}(s), modes{m} );
                alphas(isnan(alphas)) = [];
                min_alphas(m) = min( [ min_alphas(m) et_pvalues( modes{m}(s), modes{m} ) ] );
                max_alphas(m) = max( [ max_alphas(m) et_pvalues( modes{m}(s), modes{m} ) ] );
                alpha_sum = alpha_sum + sum( alphas );
            end
            mean_alphas(m) = alpha_sum/(sizes(m)*(sizes(m)-1));
        end
        
        % order the modes by rank then size
        scores = ranks*feature.context.repeat+sizes;
        [scores order] = sort( scores, 'descend' );
        
        et_info = newErgodicInfo();
        et_info.ergodic = ~isempty(modes);
        et_info.modes = length( modes );
        et_info.mode_lists = modes(order);
        et_info.mode_start_times = times(order);
        et_info.mode_periods = feature.context.tmax - times(order);
        et_info.mode_min_alphas = min_alphas(order);
        et_info.mode_max_alphas = max_alphas(order);
        et_info.mode_mean_alphas = mean_alphas(order);
        et_info.mode_sizes = sizes(order);
        et_info.mode_ranks = ranks(order);
        
        et_info.non_stationary = sum( ~isnan( st_failure_codes ) );
        et_info.st_failure_codes = st_failure_codes;
        % non-ergodic but stationary data: total - non-stationary - ergodic
        et_info.non_ergodic = feature.context.repeat - et_info.non_stationary - sum( ergodic_samples );
        
        et_info.ts_measurements = ts_measurement_counts;
        et_info.st_start_times = st_start_times;
        et_info.st_periods = st_periods;
        et_info.st_window_widths = st_window_widths;
        et_info.st_window_counts = st_window_counts;
        et_info.alpha = et_alpha;
        et_info.trace = et_pairs;
        et_info.pvalues = et_pvalues;
        
        et_info.('walltime') = etime( clock(), tic_time );
        et_info.('dirty') = true;
        et_info.('persist') = true;
        feature.context = saveVariable( feature.context, et_info, cache_name, rfile );
    end
end