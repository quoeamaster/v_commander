// GNU Affero General Public License V.3.0 or AGPL-3.0
//
// V.Commander
// Copyright (C) 2021 - quoeamaster@gmail.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

module vcommander

// Parsed_flag - a structure used during the argument parsing phase.
struct Parsed_flag {
mut:
	// name - the long (--flag) or short (-F) flag name.
	name string	
	// value_in_string - the associated value in string. 
	// Even though the flag's target value could be int, float etc; during the parsing phase, 
	// all values are treated as string.
	value_in_string string

	// possible_bool_type - whether this flag is a possible bool or not. 
	// For most cases, a bool flag could optionally NOT providing a value (which means "true").
	possible_bool_type bool
}