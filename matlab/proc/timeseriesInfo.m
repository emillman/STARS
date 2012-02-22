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

% this function records information about the timeseries feature

function [ feature, ... % returned to maintain cache consistency
    ts_info ] ...       % information describing the feature
    = timeseriesInfo( feature ) % feature to gather information about

    % failure case of function is to return an empty ts_info, ~isstruct
    ts_info = {};

    tic_time = clock();
    
    % attempt to load the data from in memory or on disk cache
    cache_name = sprintf('%s_%s_r%d_info', feature.name, feature.context.config, feature.context.run );
    rfile = sprintf('%s/ana/r%d/%s_info.mat', feature.context.config, feature.context.run, feature.name);

    [ success, info, feature.context ] = loadVariable( feature.context, cache_name, rfile );

    % return cache copy, or create information from scratch
    if success && ~isempty( info )
        ts_info = info;
    else
        % load the timeseries feature in question and assess the data
        display(sprintf('creating tme-series info for %s', cache_name ) );
        [ feature, data ] = timeseriesData( feature );
        if timeseriesValid( data )
            
            ts_info = newTimeSeriesInfo();
            ts_info.tmin = feature.context.tmin; % start of feature time
            ts_info.tmax = data.times(end); % end of feature time
            ts_info.tfirst = data.times(1); % time of first measurement
            ts_info.size = length( data.times ); % number of measurements in feature
            ts_info.count = ts_info.size;
            
            % 
            if ts_info.count > 1
                seps = data.times - [ feature.context.tmin; data.times(1:end-1) ];
                ts_info.tsep_min = max( min( seps(2:end-1) ), 0 );
                ts_info.tsep_max = max( seps(2:end-1) );
                ts_info.tsep = seps; % interval between values
                
                ts_info.vmin = min( data.values );
                ts_info.vmax = max( data.values );
                ts_info.vunique_count = length( unique( data.values ) );
            end
            
            ts_info.('walltime') = etime( clock(), tic_time );
            ts_info.('dirty') = true;
            ts_info.('persist') = true;
            feature.context = saveVariable( feature.context, ts_info, cache_name, rfile );
        end
    end
    
end