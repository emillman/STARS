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
function [ rcode ... % return code of analysis, 0 is success, all other values are failure codes
    ] = analyzeParameter( script ) % name of script containing configuration

    % fail by default
    rcode = 1;

    % construct the context and output to commandwindow
    % also get list of features.
    [ context, features ] = makeContext( script );
    context
    
    try
        % there many be several types of features, make sure we only process
        % those marked as timeseries
        features = featureSelect( features, 'ts' );
        feature_count = length( features );

        % all features for each repeat, this is done to minimize hitting the
        % store_path as multiple features in a single repeat can use the same
        % raw data.
        for r = context.first_repeat:context.repeat
            for f = 1:feature_count
                % initialize the current feature: attach context and set repeat
                % specific values
                current_feature = features{f};
                current_feature.('context') = context;
                current_feature.context.('run') = context.runs(r);
                % analyze the repeat, cache is a pointer so it should be
                % syncronized for non matlabpool runs
                current_feature = analyzeFeatureRepeat( current_feature );
                % keep cache synced
                context.cache = current_feature.context.cache;
                clear current_feature;
            end
        end

        % all features, this is done as a second pass to minimize hitting the
        % store_path and to reduce cache misses
        for f = 1:feature_count
            % initialize the current feature: attach context
            current_feature = features{f};
            current_feature.('context') = context;
            current_feature = analyzeFeature( current_feature );
            % keep cache synced
            context.cache = current_feature.context.cache;
            clear current_feature;
        end
        
        % make call to control function after analysis has finished.
        func_ptr = str2func( context.control_func );
        [ rcode, context ] = func_ptr( context, features );
        
        % success if we make it to the end without error
        rmdir( context.temp_path, 's' );
    catch me
        log_crashInfo( me, context );
        rmdir( context.temp_path, 's' );
        rethrow( me );
    end
    
end
