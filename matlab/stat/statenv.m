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

if isempty(whos('st_minitems'))
    st_minitems = 125;
end
if isempty(whos('st_alpha'))
    st_alpha = 0.05;
end
if isempty(whos('st_minwindows'))
    st_minwindows = 5;
end
if isempty(whos('st_mintime'))
    st_mintime = 100;
end
if isempty(whos('st_minincrement'))
    st_minincrement = 0.02;
end

if isempty(whos('et_alpha'))
    et_alpha = 0.05;
end
if isempty(whos('et_minmodesize'))
    et_minmodesize = 2;
end
if isempty(whos('et_minsize'))
    et_minsize = 0;
end
if isempty(whos('cdf_maxbins'))
    cdf_maxbins = 45;
end

if isempty(whos('cdf_maxtries'))
    cdf_maxtries = 1000;
end

if isempty(whos('cdf_maxchange'))
    cdf_maxchange = Inf;
end

if isempty(whos('cdf_minchange'))
    cdf_minchange = -Inf;
end

STAT_MEAN = 1;
STAT_MEDIAN = 2;
STAT_STD = 3;
STAT_VAR = 4;
STAT_PSEC = 5;
STAT_SUM = 6;
STAT_COUNT = 7;
STAT_MAX = 8;
STAT_MIN = 9;
STAT_SKEW = 10;
STAT_CSEC = 11;