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

% this function performs the time-series statistical analysis on the
% specified feature repeat.
function [ feature ... % feature passback to keep cache synced
    ] = analyzeFeatureRepeat( feature ) % feature to analyze

    assert( featureValid( feature ), 'feature parameter is not valid' );
    assert( isfield( feature, 'context' ), 'feature is missing context field' );
    assert( isfield( feature.context, 'run' ), 'feature.context is missing run field' );

    display('--------------------------------------------------------------------------------');
    display(sprintf('Starting %s sample %d feature %s', feature.context.config, feature.context.run, feature.name ) );
    display('--------------------------------------------------------------------------------');
    
    try
        feature = timeseriesData( feature );

        feature = timeseriesInfo( feature );

        feature = stationaryInfo( feature );
    catch me
        log_crashInfo( me, feature.context, rmfield( feature, 'context' ) );
        rethrow(me); 
    end

end
