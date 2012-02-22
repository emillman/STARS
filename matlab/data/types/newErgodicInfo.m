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

function [ et_info ] = newErgodicInfo()

    et_info = struct();
    et_info.('ergodic') = false;
    et_info.('modes') = nan;
    et_info.('mode_lists') = {};
    et_info.('mode_start_times') = [];
    et_info.('mode_periods') = [];
    et_info.('mode_min_alphas') = [];
    et_info.('mode_max_alphas') = [];
    et_info.('mode_mean_alphas') = [];
    et_info.('mode_sizes') = [];
    et_info.('mode_ranks') = [];
    
    et_info.('non_stationary') = nan;
    et_info.('non_ergodic') = nan;
    
    et_info.('ts_measurements') = [];
    et_info.('st_failure_codes') = [];
    et_info.('st_start_times') = [];
    et_info.('st_periods') = [];
    et_info.('st_window_widths') = [];
    et_info.('st_window_counts') = [];
    
    et_info.('pvalues') = [];
    et_info.('trace') = [];

end