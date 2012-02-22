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

% this function visualizes information about the steady-state search
% process performed

function [] = plotSteadyStateSearchTrace(context, info)

        scatter( info.trace(:,1)'.*info.trace(:,2)', info.trace(:,4)', '.' );
        scatter( info.trace(info.chosen_width,1)'.*info.trace(info.chosen_width,2)', info.trace(info.chosen_width,4)', 'o' );
        title('scatter of p_value for steady-state time');
        xlabel('duration of stady-state');
        ylabel('p_value');
end
