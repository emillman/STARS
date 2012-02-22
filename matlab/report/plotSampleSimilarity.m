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

function [] = plotSampleSimilarity( context, info, par )

    map = info.pvalues;
    row_score = nan( size( map, 1 ), 1 );
    row_fail = nan( size( map, 1 ), 1 );

    for row = 1:size( map, 1 )
        map( row, isnan( map(row,:) ) ) = 0;
        row_score(row) = sum( map(row, map(row,:) > info.alpha ) );
        map(row,:) = sort( map(row,:), 'descend' );
        row_fail(row) = sum( map(row,:) <= info.alpha );
    end

    [scores order] = sort( row_score, 'descend' );

    map = map(order,:);
    map(:,1) = [];

    contour(map , 7 );
    view( 0 , -90 );
    title('Ergodicity of samples in ensemble');
    xlabel('statistical similarity (0-to-1 decreasing)');
    ylabel('samples in order of ergodicity (descending)');

end