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

// test_structure_building_1 - build a Command structure plus setting the "help" function.
fn test_structure_building_1() {
	println("\n### command_structures_test.test_structure_building_1 ###\n")

	mut cmd := Command{
		name: "test_cmd"
		usage: "test_cmd [arguments]"
		short_description: "test_cmd is a demo purpose command which simply prints a 'hello world'."
		description: "test_cmd is a demo purpose command which simply prints a 'hello world'.\nIn general it also acts as a reference on how to use the v.commander library :)"
	}
	assert cmd.usage == "test_cmd [arguments]"

	cmd.version = "1.0.0 rc"
	assert cmd.version == "1.0.0 rc"

	// default [help] message
	mut msg := cmd.help()
	// TODO: update the validation logic later...
	assert msg == "TBD - default implementation on help"

	msg = cmd.help(fn (c &Command) string {
		return "welcome to the help menu for command $c.name~"
	})
	assert msg == "welcome to the help menu for command test_cmd~"

	msg = cmd.example(fn (c &Command) string {
		return "Example on how to use test_cmd:\nthis is the result~~\n\nNice~"
	}) or {
		// display err message why it failed
		"caught exception, reason [${err}]"
	}
	assert msg == "Example on how to use test_cmd:\nthis is the result~~\n\nNice~"
}

// test_add_subcommands - test on whether sub-commands could be appended.
fn test_add_subcommands() {
	println("\n### command_structures_test.test_add_subcommands ###\n")

	mut parent := Command{
		name: "parent"
	}
	child1 := Command{
		name: "child_1"
	}
	child2 := Command{
		name: "child_2"
	}
	parent.add_commands(child1, child2)
	assert parent.sub_commands.len == 2
}

// test_run_handler - test on running the [run] function.
fn test_run_handler() {
	println("\n### command_structures_test.test_run_handler ###\n")

	mut cmd := Command{
		name: "parent"
	}
	// run without a handler ... cause exception
	mut status := i8(main.status_fail)
	status = cmd.run() or {
		assert "$err" == "[Command][run] invalid handler, []"
		i8(status_fail)
	}
	assert status == i8(status_fail)

	// run_handler fn for test
	run_fn := fn (c &Command, args []string) ?i8 {
		if c.name == "parent" {
			return i8(main.status_ok)
		} else {
			return error("expected to be `parent` command but... it was $c.name")
		}
	}
	// reset
	status = i8(main.status_fail)
	status = cmd.run(run_fn) or {
		assert "should not have error for the 1st function, instead should return ${i8(main.status_ok)}, err -> $err" == ""
		i8(main.status_fail)
	}
	assert status == i8(main.status_ok)
	// run again without providing the fn pointer (which means re-use the existing fn)
	status = i8(main.status_fail)
	status = cmd.run() or {
		assert "should not have error for the 1st function, instead should return ${i8(main.status_ok)}, err -> $err" == ""
		i8(main.status_fail)
	}
	assert status == i8(main.status_ok)


	// run_handler fn with error
	run_err_fn := fn (c &Command, args []string) ?i8 {
		return error("Throw exception no matter what...")
	}
	// reset
	status = i8(main.status_fail)
	status = cmd.run(run_err_fn) or {
		assert err.msg == "[Command][run] error found, reason: Throw exception no matter what..."
		i8(main.status_ok)
	}
	assert status == i8(main.status_ok)
}

// test_example_handler - test on example_handler.
fn test_example_handler() {
	println("\n### command_structures_test.test_example_handler ###\n")

	mut cmd := main.Command{
		name: "parent"
	}
	// no fn supplied
	mut msg := cmd.example() or {
		"$err"
	}
	assert msg == "[Command][example] invalid handler -> []"

	// supply a valid fn
	msg = cmd.example(fn (c &Command) string {
		return "cool example."
	}) or {
		panic("error [$err]")
	}
	assert msg == "cool example."

	// no fn supplied again, re-use the previous handler
	msg = cmd.example() or {
		"$err"
	}
	assert msg == "cool example."
}

// test_args_parsing_0 - test on argument parsing.
fn test_args_parsing_0() {
	println("\n### command_structures_test.test_args_parsing_0 ###\n")

	mut cmd := Command{
		name: "parent1"
	}
	// set arguments...
	cmd.set_arguments(["--E", "a=b", "-h"])
	cmd.set_flag(true, "E", "", flag_type_map_of_string, "", false)
	cmd.set_flag(false, "", "h", flag_type_bool, "", true)

	mut status := i8(main.status_fail)
	status = cmd.run(fn (c &Command, args []string) ?i8 {
		// length check...
		if args.len == 3 {
			return i8(main.status_ok)
		}
		return error("expect argument length to be exactly 3")
	}) or {
		assert "[Command][run] error found, reason: expect argument length to be exactly 3" == "$err"
		i8(main.status_fail)
	}
	assert status == i8(main.status_ok)
	assert cmd.parsed_local_flags_map.len == 1
	assert cmd.parsed_forwardable_flags_map.len == 1
	assert ("E" in cmd.parsed_local_flags_map) == true
	assert ("unknown" in cmd.parsed_local_flags_map) == false
	v := cmd.parsed_local_flags_map["E"]
	match v {
		map[string]string {
			assert ("a" in v) == true
			assert ("unknown" in v) == false
		}
		else {}
	}
	v2 := cmd.parsed_forwardable_flags_map["h"]
	match v2 {
		bool {
			assert v2 == true
		}
		else {}
	}
	// not available key...
	v3 := cmd.parsed_local_flags_map["unknown"]
	match v3 {
		int {
			println("### never happen...")
		}
		else {
			assert "unknown sum type value" == "$v3"
		}
	}

	// TODO: handling on parsing...
	cmd = Command{
		name: "parent2"
	}
	cmd.set_arguments(["--config", "/var/app.config", "-kv", "age=18", "--trace", "--keyValue", "name=peter"])
	cmd.set_flag(true, "config", "c", flag_type_string, "", true)
	cmd.set_flag(true, "trace", "", flag_type_bool, "", true)
	cmd.set_flag(false, "keyValue", "kv", flag_type_map_of_string, "", false)

	cmd.run(fn (c &Command, args []string) ?i8 {
		return i8(status_ok)
	}) or {
		panic("$err")
	}
	assert cmd.args.len == 7
	assert cmd.parsed_local_flags_map.len == 2
	assert cmd.parsed_forwardable_flags_map.len == 1
	assert ("keyValue" in cmd.parsed_forwardable_flags_map) == true
	assert ("kv" in cmd.parsed_forwardable_flags_map) == false
	v4 := cmd.parsed_forwardable_flags_map["keyValue"]
	match v4 {
		map[string]string {
			assert v4.len == 2
			assert ("age" in v4) == true
			assert ("name" in v4) == true
			assert ("unknown" in v4) == false
			
			assert v4["age"] == "18"
			assert v4["name"] == "peter"
			assert v4["unknown"] == "" // default value for a map[string]string == ""
			assert typeof(v4["age"]).name == "string"
		}
		else {}
	}
}

// test_adding_flags - test adding local / forwardable flags
fn test_adding_flags() {
	println("\n### command_structures_test.test_adding_flags ###\n")

	mut cmd := Command {
		name: "parent"
	}
	// add some local flag(s)
	cmd.set_flag(true, "help", "h", flag_type_bool, "whether help message should be displayed.", false)
	cmd.set_flag(true, "config", "c", flag_type_string, "config file location", true)
	assert cmd.local_flags.len == 2

	// add some forwardable flag(s)
	cmd.set_flag(false, "profile", "", flag_type_bool, "whether profiling is applied.", true)
	cmd.set_flag(false, "debugFile", "d", flag_type_string, "debug file location", false)
	assert cmd.forwardable_flags.len == 2
	// [debug]
	println("flags: local ->\n${cmd.local_flags}\nforwardable ->\n${cmd.forwardable_flags}")
}

// *** VLang bug discoveries... ***

type AAny = int|string|map[string]string|map[string]AAny

// test_map_of_any_bug - BUG~~~ map of SumType has error... could not be casted correctly during runtime...
fn test_map_of_any_bug() {
	println("\n### command_structures_test.test_map_of_any_bug ###\n")

	// BUG~~~ map of SumType has error... could not be casted correctly during runtime...
	mut test := map[string]AAny{}

	test["key_int"] = 123
	test["key_kv"] = map[string]string{}

	mut kv := test["key_kv"]
	//println("!!! $kv")
	if kv is map[string]string {
		//println("!!! $kv")
		//kv["message"] = "hello world" <- fail as AAny has no index capability????
	}
	mut iv := test["key_int"]
	if iv is int {
		//println("!!! $iv")
		println("hey int $iv")
	}

	for k, v in test {
		println("once ${typeof(v).name}")
		if v is int {
			println("int $k -> $v")
		} else if v is map[string]string {
			println("b4 ${typeof(v).name}")
			v1 := test[k]
			/* proved not working
			if v1 is map[string]string {
				println("after ${typeof(v1).name}")
				//v1["2nd"] = "something"
			}
			*/

			// *** workaround
			match mut v1 {
				map[string]string {
					v1["gender"] = "U"
					v1["hobbies"] = "skating,swimming,running"
				}
				else {}
			}
			println("kv $k -> $v, ${typeof(v).name}")
		}
	}
	println("*** final contents -> $test")

	// test ... use multiple set methods + structs of diff type e.g. Flag_int
	// test ... use array instead of map (plain Any)
	// test ... use array instead of map (struct e.g. Flag_int)
}

// test_array_of_any_bug - the BUG or ways to make it work... on Array(s)
fn test_array_of_any_bug() {
	println("\n### command_structures_test.test_array_of_any_bug ###\n")

	mut list := []AAny{len: 3, cap: 3, init: AAny(0)}
	list[0] = AAny(101)
	list[2] = AAny("happy ending")

	mut m := map[string]string{}
	m["age"] = "18"
	m["name"] = "peter"
	list[1] = AAny(m)

	println("### list -> $list")

	// normal for loop
	for idx, x in list {
		println("at [$idx] -> $x")
		match mut x {
			map[string]string {
				println("**** map[string]string -> value $x")
				x["age"] = "999"
				x["hobby"] = "skating"
				println("**** AFTER updating map[string]string -> value $x")
			}
			else {}
		}
	}
	// access a member to update
	// BUG ... won't work for this way (need to use match syntax)
	mut x := list[1]
	if x is map[string]string {
		println("### a map of string found -> $x and type ${typeof(x).name}")
	}

	// finding(s)... the list[idx] approach WILL work if...
	// 1. declare x to assign the list[1] element
	// 2. match mut x to "match" the type; do whatever you want 
	// 3. for match, must exhaust the types or supply else {}
	// then... it WORKS
	x = list[1]
	println("\n*** typeof map[string]string -> ${typeof(x).name}")
	match mut x {
		map[string]string {
			x["gender"] = "m"
		}
		else {}
	}
	println("### final contents -> $list")
}