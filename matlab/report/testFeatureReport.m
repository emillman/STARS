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

% this script generates a report for the feature of interest based on the
% analysis results
function [] = testFeatureReport( features, ... % feature names to report analysis results for
                            sources, ... % sources of feature data
                            make_tables, ... % make data tables as part of report
                            overlay, ... % use subplot to reduce the number of figured produced
                            plot_types, ... % 0 linear, 1 semilogx, 2 semilogy, 3 loglog
                            min_samples ) % do not plot or report results based on fewer than X samples
                        
    [ contexts, infos, cdfs ] = getFeatureData( features, sources );
    
    %contexts{1}{1,1} = log_display( contexts{1}{1,1},          '------------------------------------------------------------------------' );
    

    
    % replicate the file it for the log_display to all contexts.
    for n = 1:length(features)
        for r = 1:size(sources,1)
            for c = 1:size(sources,2)
                if ~isempty( contexts{n}{r,c} )
                    contexts{n}{r,c} = contexts{1}{1,1};
                end
            end
        end
    end
    
    if make_tables
        %tableStationarityResults( features, infos );
        tableErgodicityResults( features, infos );
        tableFeatureResults( features, infos, cdfs );
    end

    for n = 1:length(features)
        fig_handle = figure(n);
        clf();
        set(gcf,'Name', ...
            sprintf('(%d) Ergodic Mode CDFs for %s', fig_handle, features{n}), ...
            'NumberTitle', 'off' );
        hold on;
        for r = 1:size(sources,1)
            legend_text = {};
            %log_display( contexts{n}{r,1}, ...
            for c = 1:size(sources,2)
                if isstruct(infos{n}{r,c}) && infos{n}{r,c}.ergodic
                    if ~overlay
                        subplot(size(sources,1),size(sources,2),(r-1)*size(sources,2)+c);
                    end
                    if infos{n}{r,c}.mode_sizes(1) >= min_samples
                        hold on;
                        plotModeDistribution( cdfs{n}{r,c}, infos{n}{r,c}, sources{r,c}{4} );
                        if infos{n}{r,c}.ergodic
                            legend_text{end+1} = sources{r,c}{5};
                        end
                        hold off;
                    end
                end
            end

            % make all subplots have the same x-axis
            plot_handles = get(gcf,'children');
            min_x = inf;
            max_x = -inf;
            for c = 1:length( plot_handles )
               lim = get( plot_handles(c), 'XLim' );
               min_x = min( min_x, lim(1) );
               max_x = max( max_x, lim(2) );
            end
            for c = 1:length( plot_handles )
               set( plot_handles(c), 'XLim', [ min_x max_x ] );
               switch plot_types{n}
                   case 1
                       set( plot_handles(c), 'XScale', 'log' );
                   case 2
                       set( plot_handles(c), 'YScale', 'log' );
                   case 3
                       set( plot_handles(c), 'XScale', 'log' );
                       set( plot_handles(c), 'YScale', 'log' );
               end
               set( plot_handles(c), 'XGrid', 'on' );
               set( plot_handles(c), 'YGrid', 'on' );
            end
            legend( legend_text, 'location', 'Best' );
        end
    end

    try
        for n = 1:length( names )
            for r = 1:size(sources,1)
                for p = 1:size(sources,2)
                    if isfield( contexts{1}{1,1}, 'log_file_identifier' )
                        fclose( contexts{1}{1,1}.log_file_identifier );
                    end
                end
            end
        end
    catch
    end
end