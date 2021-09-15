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

[heap]
struct Vehicle {
	name string
	num_of_wheels int
}

fn test_reference_assignment() {
	mut vehicles := []&Vehicle{cap:3}
	vehicles << &Vehicle{ name: "car", num_of_wheels: 4 }
	vehicles << &Vehicle{ name: "motorcycle", num_of_wheels: 2 }
	vehicles << &Vehicle{ name: "lorry", num_of_wheels: 4 }

	// [warn] if bike assigned to Vechicle would have 
	// {annot assign a reference to a value (this will be an error soon) left=Vehicle false right=Vehicle true ptr=true}
	// mut bike := Vehicle{name: "motorcycle"}
	//
	// [solution] bike assigned to &Vehicle{...} would be ok, since both sides' types are references (ptr) now
	mut bike := &Vehicle{name: "motorcycle"}
	for x in vehicles {
		if bike.name == x.name {
			bike = x
			break
		}
	}
	assert bike.num_of_wheels == 2
}