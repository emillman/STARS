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

% this function performs the steps needed to analize a single parameter
% using the distributed computing toolbox
function [ rcode ... % return code of analysis, 0 is success, all other values are failure
    ] = parfor_analyzeParameter( script ) % name of script containing configuration

    % fail by default
    rcode = 1;

    [ g_context, g_features ] = makeContext(script);
    g_context
    
    try
        % there many be several types of features, make sure we only process
        % those marked as timeseries
        g_features = featureSelect( g_features, 'ts' );
        feature_count = length( g_features );

        % features need to be segmented so that parfor can run more efficiently
        feature_repeats = feature_count * g_context.repeat;
        features = cell( feature_repeats, 1 );
        
        % create feature cell-array to be used in parfor, prime context
        % values
        for f = 1:feature_repeats
            repeat = ceil( f / feature_count );
            f_idx = feature_count + f - feature_count*repeat;
            features{f} = g_features{ f_idx };
            features{f}.('context') = rmfield( g_context, 'cache' );
            features{f}.context.temp_path = [ g_context.temp_path filesep randomdir ];
            features{f}.context.('run') = g_context.runs(repeat);
        end
        
        first_run = g_context.runs( min( g_context.first_repeat, g_context.max_repeat ) );
        
        % process the feature repeats using distributed matlabpool
        parfor f = 1:feature_repeats
            current_feature = features{f};
            % skip past feature repeats which have already been processed
            if current_feature.context.run >= first_run
                % the cache is specific to the parfor instance, must be
                % created inside to avoid overhead
                current_feature.context.('cache') = newCache( g_context.cache );
                if exist( current_feature.context.temp_path, 'dir' ) ~= 7
                    mkdir( current_feature.context.temp_path );
                end
                current_feature = analyzeFeatureRepeat( current_feature );
                % clean up temp files created by parfor instance
                rmdir( current_feature.context.temp_path, 's' );
            end
        end
        
        % process the featurs using distributed matlabpool
        parfor f = 1:feature_count
            current_feature = g_features{f};
            % the cache is specific to the parfor instance, must be created
            % inside to avoid overhead
            current_feature.('context') = rmfield( g_context, 'cache' );
            current_feature.context.cache = newCache( g_context.cache );
            current_feature.context.temp_path = [ g_context.temp_path filesep randomdir ];
            if exist( current_feature.context.temp_path, 'dir' ) ~= 7
                mkdir( current_feature.context.temp_path );
            end
            current_feature = analyzeFeature( current_feature );
            % clean up temp files created by parfor instance
            rmdir( current_feature.context.temp_path, 's' );
        end

        func_ptr = str2func( g_context.control_func );
        [ rcode, g_context ] = func_ptr( g_context, g_features );
        
        % success if we make it to the end, remove temp files
        rmdir( g_context.temp_path, 's' );
    catch me
        log_crashInfo( me, g_context );
        rmdir( g_context.temp_path, 's' );
        rethrow( me );
    end
end
