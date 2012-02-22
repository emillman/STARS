//
// Copyright (C) 2011 Eamon Millman
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//

package stars.instrument;

//
// TODO auto-generated module
//
simple Instrument
{
    parameters:
        string prefix = default("unknown"); // prefix to append to config name
        string path = default("results/");
        string format = default("");
        int compress = default(1);
        int maxBytes @unit("B") = default(0B);
        bool enabled = default(false);
        bool readable = default(false);
        double startTime @unit("s") = default(0s);
        
    gates:
        input in;
}
