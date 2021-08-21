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

module main

pub const (
	status_ok 			= 1
	status_fail 		= 2
	status_unknown 	= 100

	flag_type_string 				= i8(10)
	flag_type_int 					= i8(20)
	flag_type_i8 					= i8(21)
	flag_type_bool 				= i8(30)
	flag_type_float 				= i8(40)
	flag_type_map_of_string 	= i8(50) // e.g. -E age=12 -E name=Peter -> { "age": 12, "name": "Peter" }
)