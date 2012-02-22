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

% this function provides the specified feature's time-series information
function [ feature, a_data ] = timeseriesEstimate( feature, ignorecache )

    tic_time = clock();
    
    cache_name = sprintf('%s_%s_p%d_estimate', feature.name, feature.context.config, feature.context.parameter );
    rfile = sprintf('%s/ana/p%d/%s_estimate.mat', feature.context.config, feature.context.parameter, feature.name );
    
    [ success, a_data, feature.context ] = loadVariable( feature.context, cache_name, rfile );
    if ~success || isempty( a_data ) || ignorecache
        display(sprintf('creating time-series ergodic estimation for %s', cache_name ) );
        raw_period = nan;
        
        raw_samples = cell( feature.context.repeat, 1 );
        
        [ feature, et_info ] = ergodicInfo( feature );
        et_samples = cell( length( et_info.mode_lists ), 1 );
        et_estimate = cell( length( et_info.mode_lists ), 1 );
        et_start_times = nan*ones( length( et_info.mode_lists ), 1 );
        stat_names = {};
        et_period = nan*ones( length( et_info.mode_lists ), 1 );
        
        % determine the sampling period
        for i = 1:feature.context.repeat
            feature.context.('run') = feature.context.runs(i);
            [ feature, ts_info ] = timeseriesInfo( feature );
            if isstruct( ts_info )
                raw_period = max( [ raw_period max( ts_info.tsep ) ] );
            end
            if et_info.ergodic
                for c = 1:length( et_info.mode_lists )
                    if ~isempty( find( et_info.mode_lists{c} == i, 1 ) )
                        [ feature, ts_data  ] = timeseriesData( feature );
                        times = ts_data.times( ts_data.times >= et_info.st_start_times(i) );
                        max_sep = max( [ times; feature.context.tmax ] - [ et_info.st_start_times(i); times ] );
                        clear times;
                        et_period(c) = max( [ et_period(c) max_sep ] );
                        et_start_times(c) = et_info.mode_start_times(c);
                    end
                end
            end
        end
        
        raw_period = 10*raw_period;
        et_period = 10*et_period;
        raw_period_used = raw_period;
        et_period_used = et_period;
        
        
        % build the samples needed for estimation
        idx = 1;
        eidx = ones( length( et_info.mode_lists ), 1 );
        for i = 1:feature.context.repeat
            feature.context.('run') = feature.context.runs(i);
            [ feature, ts_data  ] = timeseriesData( feature );
            if timeseriesValid( ts_data )
                [ raw_samples{idx} raw_period_used ] = sampleTS( ts_data, feature.stats, raw_period, feature.context.tmin, feature.context.tmax );
                idx = idx + 1;
                if et_info.ergodic
                    for c = 1:length( et_info.mode_lists )
                        if ~isempty( find( et_info.mode_lists{c} == i, 1 ) )
                            [ et_sample, et_period_used(c) ] = sampleTS( ts_data, feature.stats, et_period(c), et_start_times(c), feature.context.tmax );
                            et_samples{c}{eidx(c)} = et_sample;
                            eidx(c) = eidx(c) + 1;
                        end
                    end
                end
            end
        end
        
        % perform the estimation
        if ~isempty( raw_samples )
            raw_estimate = estimateTS( raw_samples, feature.stats );
            if et_info.ergodic
                for c = 1:length( et_info.mode_lists )
                    et_estimate{c} = estimateTS( et_samples{c}, feature.stats );
                end
            else
                et_estimate = {};
            end
        else
            raw_estimate = {};
            et_estimate = {};
        end
        
        a_data = newAveragedData();
        
        if isstruct( raw_estimate )
            
            a_data.raw_times = raw_estimate.times;
            a_data.raw_values = raw_estimate.values;
            a_data.raw_counts = raw_estimate.counts;
            a_data.raw_period = raw_period_used;
            
            a_data.('stats') = length( raw_estimate.stat_names );
            a_data.('title') = raw_estimate.title;
            a_data.('units') = raw_estimate.units;
            a_data.('stat_names') = raw_estimate.stat_names;
            
            if et_info.ergodic

                a_data.mode_periods = et_period_used;
                a_data.mode_values = cell( 1, et_info.modes );
                a_data.mode_counts = cell( 1, et_info.modes );
                
                for m = 1:et_info.modes
                    a_data.mode_times{m} = et_estimate{m}.times;
                    a_data.mode_values{m} = et_estimate{m}.values;
                    a_data.mode_counts{m} = et_estimate{m}.counts;
                end

            end

        end
        
        a_data.('dirty') = true;
        a_data.('persist') = true;
        a_data.('walltime') = etime( clock(), tic_time );
        feature.context = saveVariable( feature.context, a_data, cache_name, rfile );

    end
    
end