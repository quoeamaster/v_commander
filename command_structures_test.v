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

import os
import strings


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
	mut child1 := Command{
		name: "child_1"
	}
	mut child2 := Command{
		name: "child_2"
	}
	parent.add_command(mut child1)
	parent.add_command(mut child2)
	assert parent.sub_commands.len == 2

	// is it the same parent??
	assert child1.name == "child_1"
	assert child1.parent.name == "parent"

	assert child2.name == "child_2"
	assert child2.parent.name == parent.name
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

	// handling on parsing...
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
// also test on parsing the flags + getting back values associated with the flags.
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

	// * test on -> parse the arguments~~
	cmd = Command{
		name: "parent2"
	}
	cmd.set_flag(true, "help", "", flag_type_bool, "", false)
	cmd.set_flag(true, "config", "", flag_type_string, "", false)
	cmd.set_flag(false, "", "E", flag_type_map_of_string, "", false)
	cmd.set_arguments([ "--config", "/app/config.json", "-E", "age=28", "-E", "name=jennie", "--help" ])
	// normal scenario -> parse_arguments() is a private fn and hence should ONLY be invoked within the [run] fn automatically.
	cmd.parse_arguments() or {
		panic("unexpected error in parsing arguments, reason [$err]")
	}
	assert cmd.args.len == 7
	mut s := cmd.get_string_flag_value(true, "config", "") or {
		panic("unexpected error in getting a valid flag, reason: $err")
	}
	assert s == "/app/config.json"
	// supply both flag and flag_short name, since flag is non "", 
	// will use that as key for search; hence flag_short wont' affect the result.
	s = cmd.get_string_flag_value(true, "config", "non-exist-key-but-not-affected") or {
		panic("unexpected error in getting a valid flag, reason: $err")
	}
	assert s == "/app/config.json"
	// non existing key
	s = cmd.get_string_flag_value(true, "unknown", "unknown") or {
		idx := err.msg.index("flag either not-found or the data-type is not a 'string'") or {
			panic("unexpected error in getting a valid flag, reason: $err")
		}
		if idx == -1 {
			panic("unexpected error in getting a valid flag, reason: $err")
		}
		""
	}
	assert s == ""
	// non found in local parsed flags...
	s = cmd.get_string_flag_value(false, "unknown", "unknown") or {
		idx := err.msg.index("flag either not-found or the data-type is not a 'string'") or {
			panic("unexpected error in getting a valid flag, reason: $err")
		}
		if idx == -1 {
			panic("unexpected error in getting a valid flag, reason: $err")
		}
		""
	}
	assert s == ""

	// * test on parsing + run
	cmd = Command{
		name: "parent3"
	}
	cmd.set_flag(true, "", "c", flag_type_string, "config file", false)
	cmd.set_flag(true, "age", "a", flag_type_int, "age number in int", false)
	cmd.set_flag(true, "classification", "", flag_type_i8, "classification number", false)
	cmd.set_flag(true, "", "G", flag_type_bool, "gender, T = Male, F = Female", false)
	cmd.set_flag(true, "price", "", flag_type_float, "price in floating point e.g. 12.99", false)
	cmd.set_flag(true, "params", "p", flag_type_map_of_string, "key value pair parameters", false)
	cmd.set_arguments([ "-c", "/app/config.json", "--age", "23", "--classification", "4", 
		"-G", "false", "--price", "12.99", "-p", "stage=a12", "--params", "factor=NONE" ])
	mut result := cmd.run(fn (c &Command, args []string) ?i8 {
		// biz logic ... etc
		assert c.args.len == 14
		return i8(status_ok)
	}) or {
		panic("unexpected error, reason: $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)
	// flag level checks
	// map-of-string
	m3 := cmd.get_map_of_string_flag_value(true, "params", "p") or {
		panic("unexpected map-string extraction, reason: $err")
	}
	assert m3.len == 2
	assert m3["factor"] == "NONE"
	assert m3["stage"] == "a12"
	// string
	s3 := cmd.get_string_flag_value(true, "", "c") or {
		panic("unexpected string extraction, reason: $err")
	}
	assert s3 == "/app/config.json"
	// int
	int3 := cmd.get_int_flag_value(true, "age", "") or {
		panic("unexpected int extraction, reason: $err")
	}
	assert int3 == 23
	// i8
	i3 := cmd.get_i8_flag_value(true, "classification", "") or {
		panic("unexpected i8 extraction, reason: $err")
	}
	// somehow auto cast is possible between int and i8...
	assert i3 == 4
	// bool
	bool3 := cmd.get_bool_flag_value(true, "", "G") or {
		panic("unexpected bool extraction, reason: $err")
	}
	assert bool3 == false
	// f32 / float
	float32 := cmd.get_float_flag_value(true, "price", "") or {
		panic("unexpected float extraction, reason: $err")
	}
	// by default float is float64... need a cast in this case
	assert float32 == f32(12.99)

	// * test on setting a non available flag cause error
	cmd = Command{
		name: "parent4"
	}
	cmd.set_arguments([ "-h", "--unknown", "999" ])
	cmd.set_flag(true, "help", "h", flag_type_bool, "help?", true)
	cmd.set_flag(true, "", "c", flag_type_string, "config file", false)
	// # should throw exception -> "[Command][parse_arguments] invalid flag --unknown."
	cmd.parse_arguments() or {
		idx := err.msg.index("invalid flag: -") or {
			panic("expected error message to contain 'invalid flag:', actual: $err")
		}
		if idx == -1 {
			panic("expected error message to contain 'invalid flag:', actual: $err")
		}
	}

	// * fail case on NOT setting a required flag through arguments...
	cmd = Command{
		name: "parent5"
	}
	cmd.set_arguments([ "-E", "age=12", "-E", "name=mary" ])
	cmd.set_flag(true, "", "E", flag_type_map_of_string, "", false)
	cmd.run(fn (c &Command, args []string) ?i8 {
		assert c.args.len == 4
		return i8(status_ok)
	}) or {
		panic("unexpected error on running a handler, reason: $err")
	}
	// add a new flag and run again
	cmd.set_flag(true, "file", "", flag_type_string, "", true)
	cmd.set_arguments([ "-E", "age=32" ])
	result = cmd.run(fn (c &Command, args []string) ?i8 {
		assert c.args.len == 2
		return i8(status_ok)
	}) or {
		idx := err.msg.index("a required local flag [file/] is missing") or {
			panic("expect error is related to missing required flag, actual: $err")
		}
		i8(status_fail)
	}
	assert result == i8(status_fail)
	// add back the "required" flag
	cmd.set_arguments([ "-E", "age=32", "--file", "/app/notes.md" ])
	result = cmd.run(fn (c &Command, args []string) ?i8 {
		assert c.args.len == 4
		return i8(status_ok)
	}) or {
		panic("unexpected error, reason: $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)

	// * test on reading the file provided through "--file" flag
	// ** mimic a real world use case on how to retrieve flag value(s)
	cmd.set_arguments([ "-C", "a sample file with some LOREM IPSUM", "--file", "./testdata/sample.txt" ])
	cmd.set_flag(false, "", "C", flag_type_string, "", true)
	result = cmd.run(fn (mut c &Command, args []string) ?i8 {
		// retrieve the flag values
		// catch the error and re-throw in a better formatted way.
		file := c.get_string_flag_value(true, "file", "") or {
			return error("[run] failed to retrieve the 'file' value, reason: $err")
		}
		// don't catch... just throw error :)
		contains := c.get_string_flag_value(false, "", "C")?

		// read the file...
		content := os.read_file(file)?
		idx := content.index(contains) or {
			return error("[run] the target file [$file] contents do NOT contain the following [$contains].")
		}
		c.write_to_output("#!# [run] contents read -> $content".bytes()) or {
			panic("unexpected error on writing to an output stream, reason: $err")
		}

		if idx != -1 {
			return i8(status_ok)
		}
		return i8(status_fail)
	}) or {
		panic("unexpected error, reason: $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)
	
	// * test on reading the stream associated with the command
	mut b_content := cmd.read_all_from_stream()
	assert b_content.len > 0
	println("\n#!#! ${string(b_content)}")
	println("\n#!#! ${b_content} - done")

	// * test on providing some arguments which is not set as flag(s)
	cmd = Command{
		name: "parent6"
	}
	cmd.set_arguments(["--config", "/app/config/abc.txt", "-E", "name=john"])
	cmd.set_flag(true, "config", "", flag_type_string, "", false)
	// deliberately NOT set the "-E" shorted flag
	result = cmd.run(fn (mut c &Command, args []string) ?i8 {
		if args.len != 4 {
			return error("expect 4 arguments, actual: $args.len")
		}
		return i8(status_ok)
	}) or {
		_ := err.msg.index("invalid flag:") or {
			panic("unexpected error to check whether 'invalid flag:' exists in the error string, $err")
			0
		}
		i8(status_fail)
	}
	// failed as an unknown flag -E is provided.
	assert result == i8(status_fail)
}

// test_remove_flag - test removing flags from local / forwardable Flag repositories.
fn test_remove_flag() {
	println("\n### command_structures_test.test_remove_flag ###\n")

	mut cmd := Command{
		name: "c1"
	}
	// * test on removing a local flag and forwardable flag
	cmd.set_flag(true, "contains", "C", flag_type_string, "contains provided text", false)
	cmd.set_flag(false, "", "a", flag_type_i8, "age value", true)
	cmd.set_flag(false, "", "b", flag_type_i8, "best score", false)
	cmd.set_arguments([ "--contains" "how are you TODAY?", "-a", "12", "-b", "100" ])
	mut b_result := cmd.parse_arguments() or {
		panic("unexpected error in parsing arguments, reason: $err")
	}
	assert cmd.remove_flag(true, "contains", "C") == true
	assert cmd.remove_flag(false, "", "a") == true
	assert cmd.local_flags.len == 0
	assert cmd.forwardable_flags.len == 1
	assert cmd.parsed_local_flags_map.len == 0
	assert cmd.parsed_forwardable_flags_map.len == 1

	// * test on after removing flags, the parse would fail due to invalid flag
	b_result = cmd.parse_arguments() or {
		idx := err.msg.index("[Command][parse_arguments] invalid flag:") or {
			panic("unexpected error in parsing arguments, reason: $err")
		}
		false
	}
	assert b_result == false

	// * test on removing a valid key but on the wrong repo; should return false...
	cmd.set_flag(true, "contains", "C", flag_type_string, "contains provided text", false)
	cmd.set_flag(false, "", "a", flag_type_i8, "age value", true)
	cmd.set_arguments([ "--contains" "how are you TODAY?", "-a", "12", "-b", "100" ])
	b_result = cmd.parse_arguments() or {
		panic("unexpected error in parsing arguments, reason: $err")
	}
	assert b_result == true
	assert cmd.remove_flag(false, "contains", "C") == false
	assert cmd.local_flags.len == 1
	assert cmd.parsed_local_flags_map.len == 1
	assert cmd.forwardable_flags.len == 2
	assert cmd.parsed_forwardable_flags_map.len == 2

	assert cmd.remove_flag(true, "", "b") == false
	assert cmd.local_flags.len == 1
	assert cmd.parsed_local_flags_map.len == 1
	assert cmd.forwardable_flags.len == 2
	assert cmd.parsed_forwardable_flags_map.len == 2

	// * test on removing a non exist flag in both repo
	assert cmd.remove_flag(true, "unknown", "u") == false
	assert cmd.local_flags.len == 1
	assert cmd.parsed_local_flags_map.len == 1
	assert cmd.forwardable_flags.len == 2
	assert cmd.parsed_forwardable_flags_map.len == 2

	assert cmd.remove_flag(false, "", "u") == false
	assert cmd.local_flags.len == 1
	assert cmd.parsed_local_flags_map.len == 1
	assert cmd.forwardable_flags.len == 2
	assert cmd.parsed_forwardable_flags_map.len == 2

	// * test on after removing non existing keys, should NOT have error
	b_result = cmd.parse_arguments() or {
		panic("unexpected error in parsing arguments, reason: $err")
	}
	assert b_result == true
	i81 := cmd.get_i8_flag_value(false, "", "b") or {
		panic("failed to parse i8 flag [-b], reason: $err")
	}
	assert i81 == i8(100)
}

fn test_subcommands_forwardable_flags() {
	println("\n### command_structures_test.test_subcommands_forwardable_flags ###\n")

	mut parent := Command{
		name: "parent"
	}
	mut child1 := Command{
		name: "child1"
	}
	mut child2 := Command{
		name: "child2"
	}
	// flags 
	// parent would have 1 local flag (name) and 1 forwardable flag (help)
	parent.set_flag(true, "name", "n", flag_type_string, "name of the user", false)
	parent.set_flag(false, "help", "h", flag_type_bool, "show help message?", false)
	// child1 has 1 local flag (age) and zero forwardable flag
	child1.set_flag(true, "age", "", flag_type_i8, "age of the user", false)
	// child2 has 0 local flag and 1 forwardable flag (country)
	child2.set_flag(false, "country", "", flag_type_string, "country name where the user lives", false)

	parent.add_command(mut child1)
	parent.add_command(mut child2)

	// * try to parse on child1 level
	child1.set_arguments(["--age", "28"])
	mut result := child1.run(fn (mut c &Command, args []string) ?i8 {
		// child1 = 1 local flag (age) + 1 inherited fwd flag (help)
		help := c.get_bool_flag_value(false, "help", "") or {
			false
		}
		assert help == false
		age := c.get_i8_flag_value(true, "age", "") or {
			i8(0)
		}
		assert age == i8(28)

		return i8(status_ok)
	}) or {
		panic("unexpected parsing for child1, reason $err")
		i8(status_fail)
	}
	// * parse child1 again with a fwd flag set
	child1.set_arguments(["--age", "28", "--help"])
	result = child1.run(fn (mut c &Command, args []string) ?i8 {
		// child1 = 1 local flag (age) + 1 inherited fwd flag (help)
		help := c.get_bool_flag_value(false, "help", "") or {
			false
		}
		assert help == true
		age := c.get_i8_flag_value(true, "age", "") or {
			i8(0)
		}
		assert age == i8(28)

		return i8(status_ok)
	}) or {
		panic("unexpected parsing for child1, reason $err")
		i8(status_fail)
	}
	// should have inherited a new persistent flag...
	assert child1.forwardable_flags.len == 1
	assert child1.local_flags.len == 1


	// * test with country argument not provided
	child2.set_arguments(["--help", "false"])
	result = child2.run(fn (mut c &Command, args []string) ?i8 {
		// child1 = 1 local flag (age) + 1 inherited fwd flag (help)
		help := c.get_bool_flag_value(false, "help", "") or {
			true
		}
		assert help == false
		ctry := c.get_string_flag_value(false, "country", "") or {
			"unknown"
		}
		assert ctry == "unknown"
		
		return i8(status_ok)
	}) or {
		panic("unexpected parsing for child2, reason $err")
		i8(status_fail)
	}
	// [debug]
	//println("##### child2 fwd -> ${child2.forwardable_flags}, ${child2.parsed_forwardable_flags_map}")

	// * test on child2 on inheritance of fwd flags from its parent
	child2.set_arguments(["--help", "--country", "Singapore"])
	result = child2.run(fn (mut c &Command, args []string) ?i8 {
		// child1 = 1 local flag (age) + 1 inherited fwd flag (help)
		help := c.get_bool_flag_value(false, "help", "") or {
			false
		}
		assert help == true
		mut ctry := c.get_string_flag_value(false, "country", "") or {
			""
		}
		assert ctry == "Singapore"
		// trying to get country in local flag would create an error
		ctry = c.get_string_flag_value(true, "country", "") or {
			err.msg.index('local flag either not-found') or {
				panic("expect to contain 'local flag either not-found', actual $err")
			}
			""
		}
		assert ctry == ""

		return i8(status_ok)
	}) or {
		panic("unexpected parsing for child2, reason $err")
		i8(status_fail)
	}
	assert child2.forwardable_flags.len == 2
	assert child2.local_flags.len == 0

	// child3 having the same / duplicated fwd flag "help" -> would have no effect on the merge
	mut child3 := Command{
		name: "child3"
	}
	parent.add_command(mut child3)
	child3.set_flag(false, "help", "H", flag_type_bool, "", false)
	child3.set_arguments(["-H", "false"])
	result = child3.run(fn (mut c &Command, args []string) ?i8 {
		help := c.get_bool_flag_value(false, "help", "H") or {
			true
		}
		assert help == false

		return i8(status_ok)
	}) or {
		panic("unexpected error, reason : $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)
	assert child3.forwardable_flags.len == 1
	// [debug]
	//println("#!# child3.fwd -> ${child3.forwardable_flags}, ${child3.parsed_forwardable_flags_map}")

	// child4 having the same / duplicated fwd flag "help" (but i8 type) -> would have no effect on the merge (no merge and should still be i8)
	mut child4 := Command{
		name: "child4"
	}
	parent.add_command(mut child4)
	child4.set_flag(false, "help", "", flag_type_i8, "", false)
	child4.set_arguments(["--help", "128"])
	result = child4.run(fn (mut c &Command, args []string) ?i8 {
		help := c.get_i8_flag_value(false, "help", "") or {
			i8(0)
		}
		assert help == i8(128)

		return i8(status_ok)
	}) or {
		panic("unexpected error, reason : $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)
	assert child4.forwardable_flags.len == 1
	// [debug]
	//println("#!# child4.fwd -> ${child4.forwardable_flags}, ${child4.parsed_forwardable_flags_map}")

	// * test on parent level....
	parent.set_arguments(["--name", "peter", "-h"])
	result = parent.run(fn (mut c &Command, args []string) ?i8 {
		name := c.get_string_flag_value(true, "name", "") or {
			"unknown"
		}
		assert name == "peter"

		help := c.get_bool_flag_value(false, "help", "h") or {
			false
		}
		assert help == true

		return i8(status_ok)
	}) or {
		panic("unexpected error, reason: $err")
		i8(status_fail)
	}
	assert result == i8(status_ok)
	assert parent.sub_commands.len == 4
	assert parent.forwardable_flags.len == 1
	assert parent.local_flags.len == 1
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

// Builder_bug_struct - a struct to test Builder behavior.
pub struct Builder_bug_struct {
mut:	
	buffer strings.Builder
pub mut:
	age i8 = i8(10)	
}

// test_builder_behavior - test how the strings.Builder works...
fn test_builder_behavior() {
	println("\n### command_structures_test.test_builder_bug ###\n")

	mut bb_struct := Builder_bug_struct{}
	bb_struct.buffer.write("hello WORLd~".bytes()) or {
		panic("failed to write to the buffer, reason: $err")
	}
	assert bb_struct.buffer.str() == "hello WORLd~"
}

/*
pub struct Command_fake {
mut:	
	// sub_commands - sub commands based on this CLI (which is the parent command in this case)
	sub_commands []Command
	// run_handler - a function to handle business logics for this CLI - the core function. Returns an integer status.
	run_handler fn(cmd &Command, args []string) ?i8
	// help_handler - a function to produce the customized help message. If provided, the default help message generation 
	// would be replaced by this function.
	help_handler fn(&Command) string = fn (c &Command) string {
		// TODO: update this impl...
		return "TBD - default implementation on help"
	}
	// example_handler - a function to provide the example in details. If provided, it would override the [description] field's value.
	example_handler fn (&Command) string
	// args - set the arguments for the CLI. This function is handy for debug purpose as well.
	args []string
	// local_flags - the Flag(s) available for the CLI. Locally scoped means only this CLI would accept these Flag(s) 
	// and not pass to the sub-commands.
	local_flags []Flag
	// forwardable_flags - the Flag(s) that would be BOTH available for the CLI and its sub-commands.
	forwardable_flags []Flag
	// parsed_local_flags_map - a map containing the parsed flag(s) values. Key is a string which would be either the following:
	// 1. flag name (e.g. --config) OR
	// 2. short flag name (e.g. -c)
	// the SIMPLE rule is if the targeted flag to be updated has a [flag] name set, use this value as the key 
	// or else use the [short_flag] name as the key
	parsed_local_flags_map 			map[string]Any = map[string]Any{}
	parsed_forwardable_flags_map 	map[string]Any = map[string]Any{}

// TODO: test on the stdout functionality... can write??? can be attached???
// TODO: add an output method ... hence printing the output to stdout + returning that string content to the caller... (good for debug)
	// stdout - the output stream for the CLI's output.
	//stdout os.File = os.stdout()

	// out_buffer - actual backing buffer for output. An auto flush is done after finished executing the [run] fn.
	//out_buffer strings.Builder
	buffer strings.Builder = strings.new_builder(1)

pub mut:
	// name - the command's name (e.g. csv)
	name string
	// usage - a short desciption on how to use the command (e.g. csv [arguments|options])
	usage string
	// short_description - a short description on how to use the command (any arbitrary string)
	short_description string
	// description - a detail description on how to use the command; 
	// if [example] function is not null, use example() to replace the description.
	description string
	// version - the version of this CLI (e.g. "1.0.1 ga")
	version string
}

fn test_command_fake() {
	mut cmd := Command_fake{}
	cmd.buffer.write("hello world".bytes()) or {
		panic("error? $err")
	}
	assert cmd.buffer.str() == "hello world"
	
	age := strconv.atoi("8") or {
		panic("failed to convert to 8, $err")
	}
	assert age == 8
}
*/
