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

% this function provides the ergodic CDF data for the specified feature
function [ feature, et_cdf ] = ergodicCDF( feature, ignorecache )

    cache_name = sprintf('%s_%s_p%d_cdf', feature.name, feature.context.config, feature.context.parameter );
    rfile = sprintf('%s/ana/p%d/%s_cdf.mat', feature.context.config, feature.context.parameter, feature.name );

    [ success, et_cdf, feature.context ] = loadVariable( feature.context, cache_name, rfile );

    if ~success || isempty( et_cdf ) || ignorecache
        statenv;
        display(sprintf('creating ergodic CDF for %s', cache_name ) );
        
        [ feature, et_info ] = ergodicInfo( feature );
        
        if et_info.ergodic
            
            % create the bins for all cdfs at once, to minimize cache
            % misses iterate over feature repeats
            
            bin_sides = [ inf; -inf ]*ones( 1, et_info.modes );
            mode_bins = cell( et_info.modes, 1 );
            mode_cdfs = cell( et_info.modes, 1 );
            
            % load each repeat seperately
            for r = 1:feature.context.repeat
                
                feature.context.('run') = feature.context.runs(r);
                [ feature, st_info ] = stationaryInfo( feature );

                if st_info.stationary
                    [ feature, ts_info ] = timeseriesInfo( feature );
                    
                    % check if it is contained in any particular mode
                    for m = 1:et_info.modes
                        
                        if ~isempty( find( et_info.mode_lists{m} == r, 1 ) )
                            
                            if ( ~isinf(bin_sides(1,m)) && ~isinf(bin_sides(2,m)) ) || ... % already tracking bin edges
                                    length( mode_bins{m} ) > cdf_maxbins || ... % have exceeded resolution limit
                                    ts_info.vunique_count > cdf_maxbins ... % contain more than the unique number of values
                                
                                bin_sides(1,m) = min( ts_info.vmin, bin_sides(1,m) );
                                bin_sides(2,m) = max( ts_info.vmax, bin_sides(2,m) );
                                mode_bins{m} = [];
                            else
                                [ feature, ts_data ] = timeseriesData( feature );
                                mode_bins{m} = unique( [ mode_bins{m}; ts_data.values(end-st_info.start_idx+1:end) ] );
                                % catch case where addition of new values
                                % exceeds maximum bin count
                                if length( mode_bins{m} ) > cdf_maxbins
                                    bin_sides(1,m) = mode_bins{m}(1);
                                    bin_sides(2,m) = mode_bins{m}(end);
                                    mode_bins{m} = [];
                                end
                            end
                            
                        end
                    end
                end
            end

            % second pass of modes constructs the cdfs
            for m = 1:et_info.modes
                
                display(sprintf('calculating CDF for mode %d', m ));
                
                use_fixed_bins = ~isempty( mode_bins{m} );
                % initialize bins to use for this mode, two buckets
                if ~use_fixed_bins
                    mode_bins{m} = [bin_sides(1,m):(bin_sides(2,m)-bin_sides(1,m))/(cdf_maxbins-1):bin_sides(2,m)]';
                end
                
                % build the cdf
                
                if length( mode_bins{m} ) == 1 % handle special case
                    mode_cdfs{m} = 1;
                else
                    calculating_bins = true;
                    last_cdf = [];
                    % to save space bins are re-calculated so that none
                    % contains more than cdf_maxchange or less than
                    % cdf_minchange percentage of the data.
                    while calculating_bins
                        
                        mode_cdfs{m} = zeros( size(mode_bins{m}) );
                        
                        for r = et_info.mode_lists{m}
                            feature.context.('run') = feature.context.runs(r);
                            [ feature, ts_data ] = timeseriesData( feature );
                            [ feature, st_info ] = stationaryInfo( feature );
                            % makeCDF expectes ts_data in reverse order
                            mode_cdfs{m} = mode_cdfs{m} + makeCDF( ts_data.values(end:-1:end-st_info.start_idx+1) , mode_bins{m}, st_info );
                        end

                        mode_cdfs{m} = mode_cdfs{m}/et_info.mode_sizes(m);
                        
                        % dont try to calculate the bins
                        if use_fixed_bins
                            calculating_bins = false;
                        else
                            % check if adding bins did not alter cdf
                            if length( last_cdf ) == length( mode_cdfs{m} )
                                if (last_cdf - mode_cdfs{m}) == 0
                                    calculating_bins = false;
                                end
                            end
                            last_cdf = mode_cdfs{m};

                            % identify the bins to split and remove
                            cdf_delta = mode_cdfs{m} - [ 0; mode_cdfs{m}(1:end-1) ];
                            split_bins = find( cdf_delta > cdf_maxchange );
                            remove_bins = find( cdf_delta < cdf_minchange );

                            % calculate new bins based on the midpoint
                            % between the bin to be split and the next
                            % bin
                            new_bins = [];
                            if ~isempty( split_bins )
                                if split_bins(end) == length( mode_bins{m} )
                                    new_bins = ( mode_bins{m}( split_bins(1:end-1) ) + mode_bins{m}( split_bins(1:end-1) + 1 ) )/2;
                                else
                                    new_bins = ( mode_bins{m}( split_bins ) + mode_bins{m}( split_bins + 1 ) )/2;
                                end
                            end
                            
                            % remove bins which contain too little data,
                            % also guarantee we never remove the last bin
                            if ~isempty( remove_bins )
                                if feature.context.debug
                                    display( sprintf( 'removing bins: %s', sprintf('%0.3f,', mode_bins{m}(remove_bins) ) ) );
                                end
                                if remove_bins(end) == length( mode_bins{m} )
                                    mode_bins{m}( remove_bins(1:end-1) ) = [];
                                else
                                    mode_bins{m}( remove_bins ) = [];
                                end
                            end
                            
                            % update the bins to calculate the cdf for
                            if ~isempty( new_bins )
                                if feature.context.debug
                                    display( sprintf( 'adding bins: %s', sprintf('%0.3f,', new_bins ) ) );
                                end
                                mode_bins{m} = sort( [ new_bins; mode_bins{m} ], 'ascend' );
                            end
                        end
                    end
                end
            end

            et_cdf = newErgodicData();
            
            et_cdf.bins = mode_bins;
            et_cdf.cdfs = mode_cdfs;
            
            et_cdf.('title') = sprintf( '(ergodic) %s', feature.title );
            et_cdf.('units') = feature.units;
            
            et_cdf.('dirty') = true;
            et_cdf.('persist') = true;
            feature.context = saveVariable( feature.context, et_cdf, cache_name, rfile );
        end
    end
end