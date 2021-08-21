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

// test_make_flag_1 - test on creation of flag<int>
fn test_make_flag_1() {
	println("### command_structures_test.test_make_flag_1 ###")
	
	age := Flag{
		flag: "age"
		short_flag: "a"
		flag_type: flag_type_int
		//default_value: 28
		usage: "age of the applicant. Accept an integer value ranging from 1 ~ 120."
	}
	assert age.flag == "age"
	mut valid := true
	valid = age.is_flag_valid() or {
		panic("error in age flag, [$err]")
		false
	}
	assert valid == true

	rating := Flag{
		short_flag: "r"
		flag_type: flag_type_i8
		//default_value: i8(5)
		usage: "rating for the movie. Accept an i8 value ranging from 1 ~ 5."
	}
	assert rating.short_flag == "r"
	valid = true
	valid = rating.is_flag_valid() or {
		panic("error in rating flag, [$err]")
		false
	}
	assert valid == true

	// error cases
	// a. missing flag and short_flag
	missing_flags := Flag {
		flag_type: flag_type_string
	}
	valid = true
	valid = missing_flags.is_flag_valid() or {
		// not found would directly throw error... so no need to check [idx] == -1 or not.
		idx := err.msg.index("either 'flag' or 'short_flag' MUST be set") or {
			panic("unexpected error, could be not found, $err")
		}
		false
	}
	assert valid == false
	
	// b. missing flag_type
	missing_flag_type := Flag {
		flag: "missing"
	}
	valid = true
	valid = missing_flag_type.is_flag_valid() or {
		err.msg.index("'flag_type' MUST be set") or {
			panic("unexpected error, could be not found, $err")
		}
		false
	}
	assert valid == false

	// c. wrong default_value comparing with the targeted type
	// explode at once... expected result :)
	/*
	wrong_type := Flag<int> {
		short_flag: "wrongType"
		default_value: "wrong_data_type"
	}
	*/
}

