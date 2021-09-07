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

// create_commands_for_sub_cmd_tests - create a parent + a child command set.
fn create_commands_for_sub_cmd_tests() (Command, Command) {
	mut course_parent_cmd := Command{
		name: "course"
	}
	mut register_child_cmd := Command{
		name: "register"
	}
	// set relationship
	course_parent_cmd.add_command(mut register_child_cmd)
	// update flags
	course_parent_cmd.set_flag(false, "help", "H", flag_type_bool, "show help?", false)
	course_parent_cmd.set_flag(true, "catalog", "", flag_type_string, "show only catalog related data", true)
	register_child_cmd.set_flag(true, "name", "N", flag_type_string, "name of the registrant", true)
	register_child_cmd.set_flag(true, "gender", "", flag_type_string, "gender of the registrant", false)
	
	return course_parent_cmd, register_child_cmd
}
// always_valid_run_handler - handy run_handler.
fn always_valid_run_handler(mut c &Command, args []string) ?i8 {
	return i8(status_ok)
}

// test_get_all_subcommand_names - test the recursive approach to get back the subcommand's names.
fn test_get_all_subcommand_names() {
	println("\n### command_structures_test.test_get_all_subcommand_names ###\n")

	mut c1 := Command{
		name: "parent c1 - level 1"
	}
	mut c1_1 := Command{
		name: "c1_1" //"child c1_1 - level 2, 1st child"
	}
	mut c1_2 := Command{
		name: "c1_2" //"child c1_2 - level 2, 2nd child"
	}
	mut c1_3 := Command{
		name: "c1_3" //"child c1_3 - level 2, 3rd child"
	}
	c1.add_command(mut c1_1)
	c1.add_command(mut c1_2)
	c1.add_command(mut c1_3)

	mut c1_1_1 := Command{
		name: "c1_1_1" //"child c1_1_1 - level 3, level 2 1st child's, 1st child "
	}
	mut c1_1_2 := Command{
		name: "c1_1_2" //"child c1_1_2 - level 3, level 2 1st child's, 2nd child"
	}
	c1_1.add_command(mut c1_1_1)
	c1_1.add_command(mut c1_1_2)

	mut c1_3_1 := Command{
		name: "c1_3_1" //"child c1_3_1 - level 3, level 2 3rd child's, 1st child "
	}
	c1_3.add_command(mut c1_3_1)

	// get all subcommands names()
	m := c1.get_all_subcommand_names("parent c1 - level 1")
	// [debug]
	println("#_# [debug] all subcommands -> $m")
	/* {
		'c1_1'  : 'parent c1 - level 1.c1_1', 
		'c1_1_1': 'parent c1 - level 1.c1_1.c1_1_1', 
		'c1_1_2': 'parent c1 - level 1.c1_1.c1_1_2', 
		'c1_2'  : 'parent c1 - level 1.c1_2', 
		'c1_3'  : 'parent c1 - level 1.c1_3', 
		'c1_3_1': 'parent c1 - level 1.c1_3.c1_3_1'
	}*/
	assert m.len == 6
	assert ('c1_1' in m) == true
	assert ('c1_3_1' in m) == true
	assert ('unknown' in m) == false
	assert m['c1_1'] == "parent c1 - level 1.c1_1"
	assert m['c1_3_1'] == "parent c1 - level 1.c1_3.c1_3_1"
	assert m['unknown'] == ""
}

// test_sub_commands_2 - test sub command parsing and operations.
fn test_sub_commands_2 () {
	println("\n### command_structures_test.test_sub_commands_2 ###\n")

	println("* normal set 1")
	mut course_parent_cmd, mut register_child_cmd := create_commands_for_sub_cmd_tests()
	// set arguments for test
	course_parent_cmd.set_arguments([ "--help", "-N", "PetER" ])
	/* // should normally use run_handler...
	mut result := course_parent_cmd.run(always_valid_run_handler) or {
		panic("a. unexpected parsing error: $err")
	}
	assert result == i8(status_ok)
	*/
	mut target_command := course_parent_cmd.parse_arguments() or {
		err.msg.index('a required local flag [catalog/] is missing') or {
			panic ("a1.1. expect parsing fail, but err msg contains 'a required local flag [catalog/] is missing.', actual [$err]")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd.set_arguments([ "--help", "false", "-N", "PetER", "--catalog", "accounting"  ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('unknown key -N') or {
			panic("a1. expect parsing fail, but err msg contains 'unknown key -N', actual [$err].")
		}
		Command{}
	}
	assert target_command.name == ""

	// set arguments for test
	course_parent_cmd.set_arguments([ "--help", "-N", "PetER", "--catalog", 'mba accounting' ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('unknown key -N') or {
			panic("a2. expect parsing fail, but err msg contains 'unknown key -N', actual [$err].")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd.set_arguments([ "--catalog", 'mba accounting' ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("a2.1. unexpected error [$err].")
		Command{}
	}
	assert target_command.name == "course"
	any_v := target_command.parsed_local_flags_map["catalog"]
	match any_v {
		string {
			assert any_v == "mba accounting"
		}
		else { panic("a2.1. expected to be string actual... $any_v") }
	}

	// arg set 2
	println("\n* normal set 2")
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "false", "register", "--name", "PetER", "--gender", "M" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("b1. parsing error, $err")
	}
	assert target_command.name == "register"

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "false", "--name", "PetER", "--gender", "M", "register" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("b2. parsing error, $err")
	}
	assert target_command.name == "register"

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "register", "--help", "false", "--name", "PetER", "--gender", "M" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("b3. parsing error, $err")
	}
	assert target_command.name == "register"

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([  "--help", "register", "--name", "PetER", "--gender", "M" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("b4. parsing error, $err")
	}
	assert target_command.name == "register"

	// error cases
	println("\n* normal set 3")
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "wrong_bool_value", "--name", "PetER", "--gender", "M" ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('invalid bool value provided [wrong_bool_value]') or {
			panic("c1. parsing error, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "register", "--help", "wrong_bool_value", "--name", "PetER", "--gender", "M" ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('invalid bool value provided [wrong_bool_value]') or {
			panic("c2. parsing error, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--name", "PetER", "--gender" ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('a required local flag [catalog/] is missing') or {
			panic ("3a.1. expect parsing fail, but err msg contains 'a required local flag [catalog/] is missing.', actual [$err]")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--gender", "--name", "PetER"  ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('a required local flag [catalog/] is missing') or {
			panic ("3a.2. expect parsing fail, but err msg contains 'a required local flag [catalog/] is missing.', actual [$err]")
		}
		Command{}
	}
	assert target_command.name == ""
	
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--catalog", "Science", "--unknown_flag", "something_would_go_wrong" ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('unknown key --unknown_flag') or {
			panic("c3.1. expect fail parsing, but contains 'unknown key --unknown_flag', actual [$err]")
		}
		Command{}
	}
	assert target_command.name == ""
	
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "register", "--gender", "--name", "PetER" ])
	// SHOULD throw ERROR... possible_bool_type check would fail for "--gender"
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('flag [gender/] is non bool-typed, but the provided value for this flag is a bool valued') or {
			panic("c3.2 expect containing 'flag [gender/] is non bool-typed, but the provided value for this flag is a bool valued', actual $err")
		}
		Command{}
	}
	assert target_command.name == ""
	
	// * test on sub-command (1 level)
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "--gender", "F", "-N", "ShEreN" "register" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("d1. unexpected [$err]")
	}
	assert target_command.name == "register"

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "--gender", "F", "-N", "ShEreN", "register", "--catalog", "finance" ])
	target_command = course_parent_cmd.parse_arguments() or {
		err.msg.index('unknown key --catalog') or {
			panic("d2. unexpected [$err]")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--gender", "F", "-N", "ShEreN", "register" ])
	target_command = course_parent_cmd.parse_arguments() or {
		panic("d3. unexpected [$err]")
	}
	assert target_command.name == "register"
	any_v2 := target_command.parsed_local_flags_map["catalog"]
	match any_v2 {
		string { assert any_v2 == "should not happen" }
		else { println("[warning] on getting an unknown value from Any-typed map -> $any_v2") }
	}
	// -N == --name
	any_v2a := target_command.parsed_local_flags_map['name']
	match any_v2a {
		string { assert any_v2a == "ShEreN" }
		else { panic("d5. unexpected, $any_v2a") }
	}
	// --gender
	any_v2b := target_command.parsed_local_flags_map['gender']
	match any_v2b {
		string { assert any_v2b == "F" }
		else { panic("d6. unexpected, $any_v2b") }
	}
	// check whether the flag is EVEN set...
	if target_command.is_flag_set(false, "help", "H") {
		// should not happen as forwardable flag has no "help" flag set
		any_v2c := target_command.parsed_forwardable_flags_map['help']
		println("$target_command.parsed_forwardable_flags_map -> $any_v2c")
		match any_v2c {
			bool { assert any_v2c == false }
			else { panic("d7. unexpected, $any_v2c") }
		}
	}
	assert target_command.is_flag_set(true, "gender", "") == true
	assert target_command.is_flag_set(true, "name", "N") == true
	// this flag should be in local and not fwd...
	assert target_command.is_flag_set(false, "name", "N") == false
	
	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "--gender", "-N", "ShEreN" "register" ])
	// --gender is non bool... should fail
	target_command = course_parent_cmd.parse_arguments() or {
		//println("d1.4 $err")
		err.msg.index('is non bool-typed, but the provided value for this flag is a bool valued') or {
			panic("d1.4. unexpected [$err]")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--help", "--gender", "F", "-N", "ShEreN" "register" ])
	// --gender is non bool... should fail
	target_command = course_parent_cmd.parse_arguments() or {
		panic("d4.2 $err")
	}
	assert target_command.name == "register"
	assert target_command.is_flag_set(true, "gender", "") == true
	assert target_command.is_flag_set(true, "name", "N") == true
	assert target_command.is_flag_set(false, "help", "") == true

	course_parent_cmd, register_child_cmd = create_commands_for_sub_cmd_tests()
	course_parent_cmd.set_arguments([ "--gender", "F", "-N", "ShEreN" "register" ])
	// --gender is non bool... should fail
	target_command = course_parent_cmd.parse_arguments() or {
		panic("d4.2 $err")
	}
	assert target_command.name == "register"
	assert target_command.is_flag_set(true, "gender", "") == true
	assert target_command.is_flag_set(true, "name", "N") == true
	assert target_command.is_flag_set(false, "help", "") == false

	// * test on 3 level hierarchy...
	// course (local: catalog:string-req, fwd: help:bool)
	// |_ register (local: name:string-req, gender:string, inherited fwd: help:bool::course_parent_cmd)
	//    |_ pay (local: method:i8-req, inherited fwd: help:bool::course_parent_cmd)
	// |_ update (local: user:string, inherited fwd: help:bool::course_parent_cmd)
	// |_ report (fwd: format:i8-req, inherited fwd: help:bool::course_parent_cmd)
	//    |_ overall (inherited fwd: help:bool::course_parent_cmd format:i8-req::report_cmd)
	//    |_ registration (local: class:string, inherited fwd: help:bool::course_parent_cmd format:i8-req::report_cmd)

	// [bug]?? weird that ... could not work when trying to update the register_child_cmd... seems reference / pointer issue.
	mut course_parent_cmd_1 := Command{ name: "course"}
	mut register_child_cmd_1 := Command{ name: "register" }
	// update flags
	course_parent_cmd_1.set_flag(false, "help", "H", flag_type_bool, "show help?", false)
	course_parent_cmd_1.set_flag(true, "catalog", "", flag_type_string, "show only catalog related data", true)
	register_child_cmd_1.set_flag(true, "name", "N", flag_type_string, "name of the registrant", true)
	register_child_cmd_1.set_flag(true, "gender", "", flag_type_string, "gender of the registrant", false)
	course_parent_cmd_1.add_command(mut register_child_cmd_1)

	mut pay_grandchild_cmd := Command{ name: "pay" }
	pay_grandchild_cmd.set_flag(true, "method", "M", flag_type_i8, "payment method 0-cash, 1-creditcard", true)
	register_child_cmd_1.add_command(mut pay_grandchild_cmd)
	
	mut update_child_cmd := Command{ name: "update" }
	update_child_cmd.set_flag(true, "user", "U", flag_type_string, "username / userid for updates", false)
	course_parent_cmd_1.add_command(mut update_child_cmd)

	mut report_child_cmd := Command{ name: "report" }
	report_child_cmd.set_flag(false, "format", "F", flag_type_i8, "report format 0-pdf, 1-json, 2-xml", true)
	course_parent_cmd_1.add_command(mut report_child_cmd)

	mut overall_grandchild_cmd := Command{ name: "overall" }
	report_child_cmd.add_command(mut overall_grandchild_cmd)

	mut registration_grandchild_cmd := Command{ name: "registration" }
	registration_grandchild_cmd.set_flag(true, "class", "C", flag_type_string, "target class for registration reporting", false)
	report_child_cmd.add_command(mut registration_grandchild_cmd)

	// check on the command hierarchy
	println("\n[debug] all sub-commands available -> \n ${course_parent_cmd_1.get_all_subcommand_names("course")}")

	// args set A
	course_parent_cmd_1.set_arguments([ "register", "pay", "--method", "0" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f1. unexpected, $err")
	}
	assert target_command.name == "pay"

	course_parent_cmd_1.set_arguments([ "--method", "0", "register", "pay" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f2. unexpected, $err")
	}
	assert target_command.name == "pay"

	// exception... as NOT able to find the command??? 
	course_parent_cmd_1.set_arguments([ "--method", "0", "pay", "register" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index('the command sequence [ pay.register ] to be executed is not VALID') or {
			panic("f3. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "register", "--method", "0", "pay" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f4. unexpected, $err")
	}
	assert target_command.name == "pay"
	assert is_help_value_correct(&target_command, false, "help", false) == true

	course_parent_cmd_1.set_arguments([ "register", "pay" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index("a required local flag [method/M] is missing") or {
			panic("f4a. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "register", "--method", "pay" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index("flag [method/M] is non bool-typed, but the provided value for this flag is a bool valued [true]") or {
			panic("f4b. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "register", "--method", "false", "pay" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index("flag [method/M] is non bool-typed, but the provided value for this flag is a bool valued [false]") or {
			panic("f4c. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""


	course_parent_cmd_1.set_arguments([ "register", "--method", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index("a required local flag [name/N] is missing") or {
			panic("f5a. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "register", "-N", "OliVer", "--method", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index("unknown key --method") or {
			panic("f5b. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "register", "-N", "OliVer", "--help" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5c. unexpected, $err")
	}
	assert target_command.name == "register"
	assert is_help_value_correct(&target_command, false, "help", true) == true

	course_parent_cmd_1.set_arguments([ "register", "-N", "OliVer", "--help", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5c. unexpected, $err")
	}
	assert target_command.name == "register"
	assert is_help_value_correct(&target_command, false, "help", false) == true

	course_parent_cmd_1.set_arguments([ "update", "--user", "JoSH" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5d.1. unexpected, $err")
	}
	assert target_command.name == "update"
	assert is_help_value_correct(&target_command, false, "help", false) == true

	course_parent_cmd_1.set_arguments([ "update", "--user", "JoSH", "--help", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5d.2. unexpected, $err")
	}
	assert target_command.name == "update"
	assert is_help_value_correct(&target_command, false, "help", false) == true

	// * report related

	course_parent_cmd_1.set_arguments([ "report", "overall", "--format", "2", "--help" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5e.1. unexpected, $err")
	}
	assert target_command.name == "overall"
	assert is_help_value_correct(&target_command, false, "help", true) == true
	assert is_i8_value_correct(&target_command, false, "format", i8(2)) == true

	// missing fwd format flag
	course_parent_cmd_1.set_arguments([ "report", "overall", "--help", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index('a required forwardable flag [format/F] is missing') or {
			panic("f5e.2. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""
	
	// course (local: catalog:string-req, fwd: help:bool)
	// |_ register (local: name:string-req, gender:string, inherited fwd: help:bool::course_parent_cmd)
	//    |_ pay (local: method:i8-req, inherited fwd: help:bool::course_parent_cmd)
	// |_ update (local: user:string, inherited fwd: help:bool::course_parent_cmd)
	// |_ report (fwd: format:i8-req, inherited fwd: help:bool::course_parent_cmd)
	//    |_ overall (inherited fwd: help:bool::course_parent_cmd format:i8-req::report_cmd)
	//    |_ registration (local: class:string, inherited fwd: help:bool::course_parent_cmd format:i8-req::report_cmd)

	course_parent_cmd_1.set_arguments([ "report", "what", "--help", "false" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		err.msg.index('invalid value, [what] is not a valid sub-command NOR a valid flag') or {
			panic("f5e.3. unexpected, $err")
		}
		Command{}
	}
	assert target_command.name == ""

	course_parent_cmd_1.set_arguments([ "report", "registration", "--help", "false" "-F", "1", "--class", "7S" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5e.4. unexpected, $err")
	}
	assert target_command.name == "registration"
	assert is_help_value_correct(&target_command, false, "help", false) == true
	assert is_help_value_correct(&target_command, false, "help", true) == false
	assert is_i8_value_correct(&target_command, false, "format", i8(1)) == true
	assert is_i8_value_correct(&target_command, false, "format", i8(10)) == false
	assert is_string_value_correct(&target_command, true, "class", "7S") == true
	assert is_string_value_correct(&target_command, true, "class", "7s") == false

	course_parent_cmd_1.set_arguments([ "report", "registration", "-F", "0" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5e.4. unexpected, $err")
	}
	assert target_command.name == "registration"
	assert is_help_value_correct(&target_command, false, "help", false) == true
	assert is_i8_value_correct(&target_command, false, "format", i8(0)) == true
	assert is_string_value_correct(&target_command, true, "class", "") == true

	course_parent_cmd_1.set_arguments([ "--catalog", "reg" ])
	target_command = course_parent_cmd_1.parse_arguments() or {
		panic("f5e.5. unexpected, $err")
	}
	assert target_command.name == "course"
	assert is_help_value_correct(&target_command, false, "help", false) == true
	assert is_string_value_correct(&target_command, true, "catalog", "reg") == true
}

fn create_commands_for_multi_run_handlers() &Command {
	mut parent := Command{
		name: "course_p",
	}
	mut child_1 := Command{
		name: "list_c1"
	}
	mut child_2 := Command{
		name: "add_c1"
	}
	mut grand_1 := Command{
		name: "category_g1"
	}
	// relationship
	parent.add_command(mut child_1)
	parent.add_command(mut child_2)
	child_1.add_command(mut grand_1)
	// flags...
	parent.set_flag(false, "documentation", "D", flag_type_bool, "documentation details", false)
	child_1.set_flag(true, "info", "I", flag_type_bool, "additional information", false)
	child_2.set_flag(true, "name", "N", flag_type_string, "course name", true)
	grand_1.set_flag(true, "category", "C", flag_type_string, "target category name", true)
	// set the run_handler
	parent.run_handler = fn (c &Command, args []string) ?i8 {
		println("*** parent -> course_p (run_handler) ***")
		return i8(status_ok)
	}
	child_1.run_handler = fn (c &Command, args []string) ?i8 {
		println("*** list_c1 (run_handler) ***")
		return i8(status_ok)
	}
	child_2.run_handler = fn (c &Command, args []string) ?i8 {
		println("*** add_c1 (run_handler) ***")
		return i8(status_ok)
	} 
	grand_1.run_handler = fn (c &Command, args []string) ?i8 {
		println("*** category_g1 (run_handler) ***")
		return i8(status_ok)
	}
	return &parent
}

// test_sub_commands_3 - test sub command with all commands having a run handler...
fn test_sub_commands_3() {
	println("\n### command_structures_test.test_sub_commands_3 ###\n")
	// parent			= course_p 		(documentation|D:bool)
	// |_ child_1		= list_c1 		(info|I:bool)
	//    |_ grand_1	= category_g1	(category|C:string-REQ)
	// |_ child_2		= add_c1 		(name|N:string-REQ)
	mut parent_cmd := create_commands_for_multi_run_handlers()
	parent_cmd.set_arguments([ "-D" ])

	// run on parent command
	mut status := parent_cmd.run() or {
		panic("a. running on parent... error, $err")
	}
	assert status == i8(status_ok)
	
	// run on child_2 level
	parent_cmd = create_commands_for_multi_run_handlers()
	parent_cmd.set_arguments([ "add_c1", "--name", "Armstrong Jr." ])
	status = parent_cmd.run() or {
		panic("b1. running on child_2 (add_c1)... error, $err")
	}
	assert status == i8(status_ok)

	// run on child_1 level
	parent_cmd = create_commands_for_multi_run_handlers()
	parent_cmd.set_arguments([ "-D", "false", "list_c1" ])
	status = parent_cmd.run() or {
		panic("b2. running on child_1 (list_c1)... error, $err")
	}
	assert status == i8(status_ok)

	// run on grand_1 level
	parent_cmd = create_commands_for_multi_run_handlers()
	parent_cmd.set_arguments([ "-D", "false", "list_c1", "-C", "public_admin", "category_g1" ])
	status = parent_cmd.run() or {
		panic("b2. running on grand_1 (category_g1)... error, $err")
	}
	assert status == i8(status_ok)

	// directly re-use the command... might have issue (since there is no reset... feature on the parsed data)
	// somehow, a Command instance would normally not be re-used; 
	// each comamnd execution is a one-off operation and exits no matter success or failure.
	// [depcrecated] logically should not happen
	/* 
	parent_cmd.set_arguments(["--documentation", "list_c1", "-I", "false" ])
	status = parent_cmd.run() or {
		panic("b2. running on grand_1 (category_g1)... error, $err")
	}
	assert status == i8(status_ok)
	*/
}

fn create_commands_for_help() (&Command) {
	mut course := Command{
		name: "course_p1"
	}
	mut list := Command{
		name: "list_c1"
	}
	mut query := Command{
		name: "query_c2"
	}
	mut subject := Command{
		name: "subject_g1_c2"
	}
	// relationship
	course.add_command(mut list)
	course.add_command(mut query)
	query.add_command(mut subject)
	// flag(s) if required...
	// the help fn
	course.help_handler = fn (c &Command) string {
		return "** help - parent -> course_p1 **"
	}
	list.help_handler = fn (c &Command) string {
		return "** help - child -> list_c1 **"
	}
	query.help_handler = fn (c &Command) string {
		return "** help - child -> query_c2 **"
	}
	subject.help_handler = fn (c &Command) string {
		return "** help - grandchild -> subject_g1_c2 **"
	}

	return &course
}

// test_help - test on the help fn. Should be able to choose the correct sub-command for displaying the correct help message.
fn test_help() {
	println("\n### command_structures_test.test_help ###\n")
	
	mut non_set_cmd := Command{
		name: "vcommand",
		short_description: "'vcommand' provides a superb experience on creating CLIs at your finger-tips.",
		description: "In order to create a CLI, you would need to brainstorm these points:\n   1. Functionalities\n   2. Documentations\n   3. Execution order\nAlso, read the tutorials...",
	}
	mut non_set_child1 := Command{
		name: "list",
		short_description: "list the commands available (demo purpose)",
		description: "Hi There~ a Long description; you can include a code sample here as well"
	}
	mut non_set_child2 := Command{
		name: "update",
		short_description: "update a specific commands (demo purpose)",
		description: "A good idea to update a specific command based on the [subject] flag."
	}
	mut non_set_grand1 := Command{
		name: "storage",
		//short_description: "storage mechanism on the update.",
		description: "where to store the results? Use flag [--medium/-M] to declare the approach."
	}
	// relationship
	non_set_cmd.add_command(mut non_set_child1)
	non_set_cmd.add_command(mut non_set_child2)
	non_set_child2.add_command(mut non_set_grand1)

	// flags
	non_set_cmd.set_flag(true, "edition", "E", flag_type_string, "get info on the specified edition value.", false)
	non_set_cmd.set_flag(true, "enroll", "", flag_type_bool, "enroll now?", true)
	non_set_cmd.set_flag(true, "", "C", flag_type_int, "classification number", true)
	non_set_cmd.set_flag(false, "values", "V", flag_type_map_of_string, "a key-value pair structure", false)

	non_set_child2.set_flag(false, "arguments", "", flag_type_map_of_string, "arguments in key-value(s)", true)

	non_set_grand1.set_flag(true, "medium", "M", flag_type_i8, "medium for storage, 0-file, 1-stdout", false)

	println("** default-help =>\n-=-=-=-=-=-=-=-=-=\n\n${non_set_cmd.help()}\n-=-=-=-=-=-=-=-=-=\n")
	non_set_cmd.set_arguments(["list"])
	println("** default-help (list) =>\n-=-=-=-=-=-=-=-=-=\n\n${non_set_cmd.help()}\n-=-=-=-=-=-=-=-=-=\n")
	non_set_cmd.set_arguments(["update", "--arguments", "fruit=apple", "--arguments", "subject=science"])
	println("** default-help (update) =>\n-=-=-=-=-=-=-=-=-=\n\n${non_set_cmd.help()}\n-=-=-=-=-=-=-=-=-=\n")
	non_set_cmd.set_arguments(["update", "--arguments", "fruit=apple", "--arguments", "subject=science", "-M", "1", "storage"])
	println("** default-help (update storage) =>\n-=-=-=-=-=-=-=-=-=\n\n${non_set_cmd.help()}\n-=-=-=-=-=-=-=-=-=\n")
	
	// * test on multi customed help fn
	mut parent_cmd := create_commands_for_help()

	// run on parent level (no need to set flags as not configured here)
	println(parent_cmd.help())

	// run on child level 
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["list_c1"])
	println(parent_cmd.help())

	// run on another child level 
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["query_c2"])
	println(parent_cmd.help())

	// run on another grand_child level 
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["query_c2", "subject_g1_c2"])
	println(parent_cmd.help())
	
	// error : unknown sub-command
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["query_c2", "unknown_sub_cmd"])
	println(parent_cmd.help())

	// error : unknown flag
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["query_c2", "subject_g1_c2", "--unknown_flag"])
	println(parent_cmd.help())

	// run on another child level 
	parent_cmd = create_commands_for_help()
	parent_cmd.set_arguments(["query_c2"])
	println(parent_cmd.help())
}

// is_help_value_correct - helper method to check whether the help flag's value is the same as [value].
fn is_help_value_correct(cmd &Command, is_local bool, key string, value bool) bool {
	v := cmd.get_bool_flag_value(is_local, key, "") or {
		println("[is_help_value_correct] failed to get value... $err")
		false
	}
	//println("[debug] extracted value -> $v vs $value, actual $cmd.parsed_forwardable_flags_map")
	return v == value
}
fn is_i8_value_correct(cmd &Command, is_local bool, key string, value i8) bool {
	v := cmd.get_i8_flag_value(is_local, key, key) or {
		println("[is_i8_value_correct] $err")
		i8(0)
	}
	return v == value
}
fn is_string_value_correct(cmd &Command, is_local bool, key string, value string) bool {
	v := cmd.get_string_flag_value(is_local, key, key) or {
		println("[is_string_value_correct] $err")
		""
	}
	return v == value
}
