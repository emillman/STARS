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

% this function performs the statistical analysis for the feature specified
function [ feature ... % passback to keep cache synced
    ] = analyzeFeature( feature ) % feature to analyze

    assert( isfield( feature, 'context' ), 'feature is missing required context field' );

    display('--------------------------------------------------------------------------------');
    display(sprintf('Starting %s parameter %d feature %s', feature.context.config, feature.context.parameter, feature.name ) );
    display('--------------------------------------------------------------------------------');
    
    try
        [ feature, info ] = ergodicInfo( feature );

        if info.ergodic
            feature = ergodicCDF( feature, true );
        end

        feature = timeseriesEstimate( feature, true );
    
    catch me
        log_crashInfo( me, feature.context, rmfield( feature, 'context' ) );
        rethrow(me); 
    end
end