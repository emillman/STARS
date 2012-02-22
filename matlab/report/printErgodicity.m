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

function [] = printErgodicity( context, info, cdf, semi_log_x )

    if isstruct( info ) && isfield( info, 'ergodic' ) && info.ergodic
        
        %chi_square = zeros( info.modes, 2 );
        min_max_mean = zeros( info.modes, 3 );

        for c = 1:info.modes
            if semi_log_x && ~isemptny(cdf.log_bins{c})
                bins = cdf.log_bins{c};
                ocdf = cdf.log_cdfs{c};
            else
                bins = cdf.bins{c};
                ocdf = cdf.cdfs{c};
            end

            %{

            out = [];%find( bins < 0 );
            if ~isempty(out)
                bins(out) = [];
                offset = ocdf(out(end));
                ocdf(out) = [];
                ocdf = ocdf - offset;
                ocdf = ocdf/sum(ocdf);
            end

            for b = 1:length( bins )
                if 0 > bins(b)
                    continue;
                end
                chi_square(c,2) = chi_square(c,2) + (( ocdf(b) - (1-exp(-5*bins(b)) ) )^2)/(1-exp(-5*bins(b)));
            end

            out = [];%find( bins > 80 );
            if ~isempty(out)
                bins(out) = [];
                ocdf(out) = [];
                ocdf = ocdf/sum(ocdf);
            end

            for b = 1:length( bins )
                if bins(b) > 80 || 0 > bins(b)
                    continue;
                end
                chi_square(c,1) = chi_square(c,1) + (( ocdf(b) - (bins(b)/80) )^2)/(bins(b)/80);
            end
            %}
            m = find( ocdf > 0.5, 1 );
            if m > 1
                yy = double(bins( m-1:m ));
                xx = double(ocdf( m-1:m ));
                tmp = polyfit( xx, yy, 1 );
                min_max_mean(c,:) = [ bins(1) bins(end) polyval( tmp, 0.5 ) ];
            else
                min_max_mean(c,:) = [ bins(1) bins(end) bins( m ) ];
            end
            

        end
      
        context = log_display( context, '|= Ergodicity Results' );
        context = log_display( context, sprintf('Modes detected: %d', info.modes ) );
        context = log_display( context, sprintf('Stationary but non-ergodic samples: %d', info.non_ergodic ) );           
        context = log_display( context, sprintf('Samples in mode(s):       [ %s]', sprintf( '%d ', info.mode_sizes ) ) );
        context = log_display( context, sprintf('Start Time of mode(s):    [ %s]', sprintf( '%0.3f ', info.mode_start_times ) ) );
        context = log_display( context, sprintf('Minimum alpha of mode(s): [ %s]', sprintf( '%0.3f ', info.mode_min_alphas ) ) );
        context = log_display( context, sprintf('Maximum alpha of mode(s): [ %s]', sprintf( '%0.3f ', info.mode_max_alphas ) ) );
        context = log_display( context, sprintf('Average alpha of mode(s): [ %s]', sprintf( '%0.3f ', info.mode_mean_alphas ) ) );
        context = log_display( context, sprintf('Minimum value of mode(s): [ %s]', sprintf( '%E ', min_max_mean(:,1) ) ) );
        context = log_display( context, sprintf('Maximum value of mode(s): [ %s]', sprintf( '%E ', min_max_mean(:,2) ) ) );
        context = log_display( context, sprintf('Average value of mode(s): [ %s]', sprintf( '%E ', min_max_mean(:,3) ) ) );

        %{
        chi_square(idx,:)'

        min_max_mean(idx,:)'

        display( sprintf( 'uniform modes: %d for %d samples', ...
            sum( chi_square(idx,1) < chi_square(idx,2) ), ...
            sum( mode_counts{p}(chi_square(idx,1) < chi_square(idx,2)) ) ...
        ) );
        display( sprintf( 'exponential modes: %d for %d samples', ...
            sum( chi_square(idx,2) < chi_square(idx,1) ), ...
            sum( mode_counts{p}(chi_square(idx,2) < chi_square(idx,1)) ) ...
        ) );

        for c = idx
            ocdf = cdf{p}.cdfs{c};
            bins = cdf{p}.bins{c};
            out = find( bins < 0 );
            if ~isempty(out)
                out = out(end);
                display( sprintf( 'start-up transients in %d accounts for %0.6f probability', c, ocdf(out) ) );
            end
        end
        %}
    else
        context = log_display( context, '|= No Ergodicity Results' );
    end
end