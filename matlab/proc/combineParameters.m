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

% this function combines and finalizes the results for an experiment
function [ rcode ] = combineParameters( script )

    % fail be default
    rcode = 1;

    [ context, features ] = makeContext(script);
    context
    
    try

        % there many be several types of features, make sure we only process
        % those marked as timeseries
        features = featureSelect( features, 'ts' );
        feature_count = length( features );      
        
        % copy over all features analyzed
        for f = 1:feature_count
            % load each parameter individually
            
            feature_struct = struct();
            
            for p = 1:context.parameters

                par_name = sprintf( 'p%d', p );
                
                % build a struct which represents the parameter results
                feature_struct.( par_name ) = struct();

                feature = features{f};
                
                base_name = feature.name; 
                base_cache_name = sprintf( '%s_%s_p%d', feature.name, context.config, p );
                base_path = [ context.config filesep 'ana' filesep sprintf('p%d', p ) ];

                % try to load the expected data.
                % et_info is required
                % et_cdf is optional
                % et_est is required
                [ success, et_info, context ] = loadVariable( context, [ base_cache_name '_info' ], [ base_path filesep base_name '_info.mat' ] );
                if success

                    feature_struct.( par_name ) = struct('info',et_info);

                    if et_info.ergodic
                        [ success, et_cdf, context ] = loadVariable( context, [ base_cache_name '_cdf' ], [ base_path filesep base_name '_cdf.mat' ] );
                        if success
                            feature_struct.( par_name ).('cdf') = et_cdf;
                        else
                            error('STARS:combineParameters','failed to find expected data %s', [ base_name '_cdf' ] );
                        end
                    end

                    [ success, et_est, context ] = loadVariable( context, [ base_cache_name '_estimate' ], [ base_path filesep base_name '_estimate.mat' ] );
                    if success
                        feature_struct.( par_name ).('estimate') = et_est;
                    else
                        error('STARS:combineParameters','failed to find expected data %s', [ base_name '_estimate' ] );
                    end
                else
                    error('STARS:combineParameters','failed to find expected data %s', [ base_name '_info' ] );
                end
            end

            feature_struct.('persist') = true;
            feature_struct.('dirty') = true;
            saveVariable( context, feature_struct, feature.name, [ context.config '.mat' ] );
            
        end

        context.('persist') = true;
        context.('dirty') = true;
        context = saveVariable( context, rmfield(context,'cache'), 'context', [ context.config '.mat' ] );

        rmdir( context.temp_path, 's' );
        rcode = 0;
        
    catch me
        log_crashInfo( me, context );
        rmdir( context.temp_path, 's' );
        rethrow( me );
    end
end
