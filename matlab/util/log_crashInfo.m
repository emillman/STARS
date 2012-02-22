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

% this script writes information relating to the failure of the engine to
% file.
function log_crashInfo( me, context, feature )

    date_time = clock();
    display(sprintf('Crash Log: %2d:%02d:%02.0f on %2d/%02d/%4d', ...
        date_time([4 5 6 3 2 1]) ));
    
    if ~isempty( whos('context' ) ) && ~isempty( context )
        context
        if context.cache_enabled
            reportCache( context.cache );
        end
    end
    if ~isempty( whos('feature' ) ) && ~isempty( feature )
        feature
    end
    if ~isempty( whos('me' ) ) && ~isempty( me )
    
        display('encountered exception when performing analysis');
        display( me.identifier );
        display( me.message )
        for i = 1:length( me.stack )
            display( me.stack(i) );
        end

    end
end