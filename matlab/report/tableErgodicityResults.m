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


function [] = tableErgodicityResults( features, infos )

    display('\begin{table}');
    display('\caption{caption}');
    display('\tabl{label}');
    display('\begin{center}');
    display('\begin{tabular}{ | l | c | c | c | c | c | }');
    display('\hline');
    display(' & \multicolumn{3}{|c|}{\textbf{Sample $X_n$}} & \multicolumn{2}{|c|}{\textbf{Mode $M_X$}} \\' );
    display('\hline');
    display('\textbf{Feature} & \textbf{Stationary} & \textbf{Non-Stationary} & \textbf{Non-Ergodic} & \textbf{Count} & \textbf{Largest} \\' );
    display('\hline');
    for n = 1:length( features )

        display(sprintf('\\multirow{%d}{*}{\\textbf{%d) %s}}', size( infos{n}, 2 ), n, features{n} ));
        
        for c = 1:size( infos{n}, 2 )
            
            stationary = '-';
            not_enough_data = '-';
            non_stationary = '-';
            non_ergodic = '-';
            mode_count = '-';
            mode_largest = '-';
            
            if ~isempty( infos{n}{1,c} )
                stationary = sprintf( '%d', sum(isnan( infos{n}{1,c}.st_failure_codes )));
                not_enough_data = sprintf( '%d', sum( infos{n}{1,c}.st_failure_codes == -2 ));
                non_stationary = sprintf( '%d', sum( infos{n}{1,c}.st_failure_codes == -1 ));

                non_ergodic = sprintf( '%d', infos{n}{1,c}.non_ergodic );

                if infos{n}{1,c}.ergodic

                    non_ergodic = sprintf( '%d', infos{n}{1,c}.non_ergodic );
                    mode_count = sprintf( '%d', infos{n}{1,c}.modes );
                    mode_largest = sprintf( '%d', infos{n}{1,c}.mode_sizes(1) );

                end
            end
            
            display( sprintf( '& $%s$ & $%s,%s$ & $%s$ & $%s$ & $%s$ \\\\', stationary, not_enough_data, non_stationary, non_ergodic, mode_count, mode_largest ) );
        end
        display('\hline');
    end

    display('\end{tabular}');
    display('\end{center}');
    display('\end{table}');
end