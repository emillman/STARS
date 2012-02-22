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

function [] = printStationarity( context, info )

    %context
    %info
    %{
    sum( info{1}.start_times < 150 )
    sum( info{1}.start_times > 450 )
    
	values = info{1}.start_times;
    values( values < 150 ) = [];
    values( values > 450 ) = [];
    
    bins = 150:10:450;
    ocdf = hist( values, bins );
    ocdf = cumsum( ocdf )/sum(ocdf);

    ecdf = ones( size( bins ) )/(450-150);
    ecdf = cumsum( ecdf )/sum(ecdf);
    
    ChiSquare = 0;
    
    for b = 1:length( bins )
        ChiSquare = ChiSquare + (( ocdf(b) - ecdf(b) )^2)/ecdf(b);
    end
    
    ChiSquare
    %}
    %clustering;
    
    if sum( ~isnan(info.st_start_times) ) > 0
        context = log_display( context,'|= Stationarity Results');
        context = log_display( context,sprintf('records exhibiting stationarity: %d, or %0.3f%% of %d total', ...
           context.repeat-info.non_stationary, ...
           100*(context.repeat-info.non_stationary)/context.repeat, ...
           context.repeat ));

        context = log_display( context,sprintf('duration of transient phase: %0.3fs min, %0.3fs mean, %0.3fs max', ...
            min( info.st_start_times ), mean( info.st_start_times( ~isnan( info.st_start_times ) ) ), max( info.st_start_times ) ));
        context = log_display( context,sprintf('period of stationarity: min %0.3fs, mean %0.3fs, max %0.3fs', ...
            min( info.st_periods ), ...
            mean( info.st_periods( ~isnan( info.st_start_times ) ) ), ...
            max( info.st_periods ) ));
    else
        context = log_display( context,'|= No Stationarity Results');
    end
    %%{
    log_display( context, sprintf('Missing Sample Data: %d', sum( isnan( info.st_window_widths ) ) ) );
    log_display( context, sprintf('Too few measurements: %d', sum( info.st_window_widths == -2 ) ) );
    log_display( context, sprintf('No Steady-State Detected: %d', sum( info.st_window_widths == -1 ) ) );
    log_display( context, sprintf('Steady-State Period too short, or too few windows: %d', sum( info.st_window_widths == -1 ) ) );
    %}
end