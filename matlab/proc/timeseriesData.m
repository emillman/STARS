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

% this function provides the specified feature's time-series data
function [ feature, ts_data ] = timeseriesData( feature )

    ts_data = {};

    tic_time = clock();
    
    cache_name = sprintf('%s_%s_r%d', feature.name, feature.context.config, feature.context.run );
    rfile = sprintf('%s/ana/r%d/%s.mat', feature.context.config, feature.context.run, feature.name );
    
    [ success, ts_data, feature.context ] = loadVariable( feature.context, cache_name, rfile );
    
    if ~success || ~timeseriesValid( ts_data )
        display(sprintf('creating time-series data for %s', cache_name ) );
        func = str2func( feature.func );
        
        try
            [ feature, ts_data ] = func( feature );
        catch me
            display( me.identifier );
            display( me.message )
            for i = 1:length( me.stack )
                display( me.stack(i) );
            end
            error('STARS:timeseriesData','exception occured in user created time-series function %s for %s run %d', feature.func, feature.name, feature.context.run );
        end

        % this throws STARS:newTimeSeriesData if user supplied ts_data is not valid
        try
            ts_data = newTimeSeriesData(ts_data);
        catch me
            error('STARS:timeseriesData','user supplied ts_data was not valid, see timeseriesValid()');
        end

        idx = ts_data.times >= feature.context.tmin & ts_data.times <= feature.context.tmax;
        ts_data.values = ts_data.values(idx);
        ts_data.times = ts_data.times(idx);

        if ~issorted( ts_data.times )
            warning('STARS:timeseriesData','time-series data is not sorted in ascending order as required!');
            [ times, idx ] = sort( ts_data.times );
            ts_data.times = times;
            ts_data.values = ts_data.values( idx );
        end

        if sum( isnan( ts_data.values ) | isinf( ts_data.values ) ) > 0
            warning('STARS:timeseriesData','values contains NaN or Inf value(s)');
        end
        ts_data.('title') = feature.title;
        ts_data.('units') = feature.units;   
        ts_data.('walltime') = etime( clock(), tic_time );
        ts_data.('dirty') = true;
        ts_data.('persist') = true;
        feature.context = saveVariable( feature.context, ts_data, cache_name, rfile );
        
    end
    
end