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

function [ rcode, context, more_runs ] = analysisErgodicControl( context, features )
    min_size = 0;
    more_runs = 0;
   
    if context.repeat > 0
        min_size = Inf;

        feature_count = length( features );
        for f = 1:feature_count

            name = sprintf('%s_%s_p%d_cdf_info', features{f}.name, context.config, context.parameter );
            file = sprintf('%s/ana/p%d/%s.mat', context.config, context.parameter, name );
            [ success, info, features{f} ] = loadVariable( context, name, file );
            if success && info.ergodic && info.count > context.ec_threshold
                min_size = min( min_size, info.count );
            end

        end
        if isinf( min_size )
            min_size = 0;
        end
    end

    if min_size >= context.ec_minsize
        rcode = 0;
    else
        if min_size > 0
            more_runs = min( [ context.max_repeat context.ec_minsize/min( min_size/context.repeat ) ] ) - context.repeat;
        else
            more_runs = context.ec_minsize;
        end

        display(sprintf('did not meet ergodicity requirements, requesting %d more repeats', more_runs ));

        more_runs = round( more_runs );
        
        rcode = 0;
    end
end