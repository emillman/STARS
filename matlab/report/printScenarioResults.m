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

function [] = printScenarioResults( contexts, infos, cdfs )

    %log_display( contexts{1}, ...
    display( ...
        '____________________________________________________________________________' );
    %log_display( contexts{1}, ...
    display( ...
        'Parameter | Stationary | Non-Ergodic | Modes | Size |  t^SS   | Alpha | Mean' );

    for c = 1:length( contexts )

        stationary = nan;
        nonergodic = nan;
        modes = nan;
        mode_size = nan;
        start_time = nan;
        alpha = nan;
        min = nan;
        mean = nan;
        max = nan;
        
        if ~isempty( contexts{c} )
        
            stationary = contexts{c}.repeat - infos{c}.non_stationary;
            nonergodic = infos{c}.non_ergodic;
            modes = infos{c}.modes;
            

            if infos{c}.ergodic
                mode_size = infos{c}.mode_sizes(1);
                start_time = infos{c}.mode_start_times(1);
                alpha = infos{c}.mode_mean_alphas(1);
                cdf = cdfs{c}.cdfs{1};
                bins = cdfs{c}.bins{1};
                min = cdfs{c}.bins{1}(1);
                max = cdfs{c}.bins{1}(end);
                mean_idx = find( cdf > 0.5, 1 );        
                if mean_idx > 1
                    yy = double(bins( mean_idx-1:mean_idx ));
                    xx = double(cdf( mean_idx-1:mean_idx ));
                    mean = polyval( polyfit( xx, yy, 1 ), 0.5 );
                else
                    mean = bins( mean_idx );
                end
            end
            %{
            %log_display( contexts{1}, ...
            display( ...
                sprintf('%9d | %10d | %11d | %5d | %4d | %7d | %5.3f | %E', ...
                c, stationary, nonergodic, modes, mode_size, round(start_time), alpha, mean ) );
            %}
            %{
            display( ...
                sprintf( '& $%d$ & $%d$ & $%d$ & $%d$ & $%0.3f$ \\\\', ...
                stationary, nonergodic, modes, mode_size, alpha ));
            %}
            %%{
            display( ...
                sprintf( '& $%d$ & $%E$ & $%E$ & $%E$ \\\\', ...
                round(start_time), min, mean, max ));
            %}
        end
        
        
        
    end

        %log_display( contexts{1}, ...
    display( ...
        '----------------------------------------------------------------------------' );
end