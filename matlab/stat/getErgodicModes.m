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

% this function finds the best ergodic group and returns its members
function [ modes, mode_ranks, mode_sizes ] = getErgodicModes( pvalues )
    statenv;
    
    repeat = size( pvalues, 1 );
    
    indexs = 1:repeat;
    
    modes = true( repeat );
    mode_sizes = sum( pvalues, 2 );
    
    % make sure sample is marked similar to itself and initialize modes
    % matrix
    for m = 1:repeat
        pvalues(m,m) = true;
        modes(m,:) = pvalues(m,:);
    end
    % create all connected set for each sample
    for m = 1:repeat
        % calculate the intersection of all samples
        for r = indexs( pvalues(m,: ) )
            modes(m,:) = modes(m,:) & pvalues(r,:);
        end
        % record size of set
        mode_sizes(m) = sum( modes(m,:) );
    end
    
    % find the common sets of all ergodic modes
    common_sets = modes;
    common_sizes = mode_sizes;
    
    % reduce modes to their most common sample(s) and save 
    last_sizes = zeros( size( common_sizes ) );
    
    while sum( abs( last_sizes - common_sizes ) ) > 0
        last_sizes = common_sizes;
        last_modes = common_sets;
        % find greatest common subset for all modes
        for m = 1:repeat
            for m2 = indexs( last_modes(:,m) );
                common_sets(m,:) = common_sets(m,:) & last_modes(m2,:);
            end
            common_sizes(m) = sum( common_sets(m,:) );
        end
    end
    
    % pick largest mode containing the common sample(s)
    largest_modes = cell( repeat, 1 );
    largest_sizes = zeros( repeat, 1 );
    largest_ranks = zeros( repeat, 1 );
    already_chosen = zeros( repeat, 1 );
    mode_is_s_new = zeros( repeat, 1 );
    s_new = 0;
    for s = 1:repeat
        set_mode = 0;
        set_size = 0;
        for m = indexs( modes(s,:) )
            if (common_sets(s,:) - modes(m,:)) >= 0
                if set_size < mode_sizes(m);
                    set_mode = m;
                    set_size = mode_sizes(m);
                end
            end
        end
        if ~already_chosen(set_mode)
            already_chosen(set_mode) = true;
            % only pick modes of sufficient size
            if set_size >= et_minmodesize
                s_new = s_new + 1;
                largest_modes{s_new} = modes(set_mode, : );
                largest_sizes(s_new) = set_size;
                largest_ranks(s_new) = common_sizes(s);
                mode_is_s_new(set_mode) = s_new;
            end
        else
            if common_sizes(s) > largest_ranks( mode_is_s_new(set_mode) )
                largest_ranks( mode_is_s_new(set_mode) ) = common_sizes(s);
            end
        end
    end
       
    if s_new > 1
        mode_list = largest_modes(1:s_new);
        mode_sizes = largest_sizes(1:s_new);
        mode_ranks = largest_ranks(1:s_new);
    else
        mode_list = {};
        mode_sizes = [];
        mode_ranks = [];
    end

    % kick out groups to remove any sub-sets from the list of modes
    [ throw_away order ] = sort( mode_sizes, 'ascend' );
    for m = 1:length( mode_list )
        for n = m+1:length( mode_list )
            if mode_list{order(n)} - mode_list{order(m)} >= 0
                mode_sizes(order(m)) = nan;
                break;
            end
        end
    end
    
    modes = mode_list(~isnan(mode_sizes));
    mode_ranks = mode_ranks(~isnan(mode_sizes));
    mode_sizes = mode_sizes(~isnan(mode_sizes));
    for m = 1:length( modes )
        modes{m} = find( modes{m} );
    end
end