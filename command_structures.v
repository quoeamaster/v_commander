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
import strconv
 
// Any - is a sum-type of acceptable values within the CLI.
type Any = i8|int|string|bool|f32| map[string]string | map[string]Any

// empty_command - a reference of an empty [Command].
const empty_command = Command{
	parent: &Command{},
	name: "__empty__"
}

// Command - a structure describing a CLI command.
[heap]
pub struct Command {
mut:
	// parent - the parent Command. Could be a reference of the [empty_command] instance.
	//parent &Command = 0 // empty pointer (0)
	parent &Command = &empty_command
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
	stdout os.File = os.stdout()
	// out_buffer - actual backing buffer for output. An auto flush is done after finished executing the [run] fn.
	out_buffer Stringbuffer = new_string_buffer(0)
	
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

// add_command - add the provided sub-command. Also updates the [parent] reference.
pub fn (mut c Command) add_command(mut cmd Command) {
	cmd.parent = &c
	c.sub_commands << cmd
}

// run - set the provided [handler] to the CLI and execute it. [run] provides the core functionality for this CLI.
pub fn (mut c Command) run(handler ...fn(mut cmd &Command, args []string) ?i8) ?i8 {
	if handler.len != 0 {
		c.run_handler = handler[0]
	} else {
		// check whether the run_handler associated is nil or not
		if isnil(c.run_handler) {
			return error("[Command][run] invalid handler, $handler")
		}
	}
	// run the args parsing before trigger the handler
	c.parse_arguments()?
	// execute the run_handler
	status := c.run_handler(c, c.get_arguments()) or {
		return error("[Command][run] error found, reason: $err")
	}
	// flush output to stdout
	mut stream := c.stdout
	// [BUG] ?? required a newline or `\0` to delimited the end of a string... c style null-delimited string.
	mut s_content := c.out_buffer.to_string(false) + "\n"
	if s_content.len > 1 {
		stream.write(s_content.bytes()) or {
			return error("[Command][run] error in writing output to stdout, reason: $err")
		}
	}
	return status
}

// help - set the provided [handler] to the CLI and execute it. [help] facilitates a customized help message if necessary.
pub fn (mut c Command) help(handler ...fn(cmd &Command) string) string {
	if handler.len != 0 {
		c.help_handler = handler[0]
	}
	// execute
	return c.help_handler(c)
}

// example - set the provided [handler] to the CLI and execute it. [example] provides a way to explain how the CLI works. 
// If provided, it would replace the [description] field's value.
pub fn (mut c Command) example(handler ...fn(cmd &Command) string) ?string {
	// TODO: bug or whatever... so the current approach is all fn_pointers need a default implementation... example_handler would return empty string instead...
	if handler.len != 0 {
		// if &c.example_handler == 0 { <- only valid if the pointer has been set at least once...
		c.example_handler = handler[0]
	} else {
		if isnil(c.example_handler) {
			return error("[Command][example] invalid handler -> $handler")
		}
	}
	return c.example_handler(c)
}

// set_arguments - set the [args] for this CLI.
pub fn (mut c Command) set_arguments(args []string) {
	c.args = args
}

// get_arguments - return either the associated [args] value OR the arguments provided by the command-line execution.
fn (c Command) get_arguments() []string {
	if c.args.len > 0 {
		return c.args
	}
	// retrieve the CLI args but excluded the first argument which is the executable name.
	return os.args[1..os.args.len]
}

// set_flag - add a Flag to the CLI. [is_local] determines whether this flag is a local or forwardable flag.
pub fn (mut c Command) set_flag(is_local bool, flag string, short_flag string, flag_type i8, usage string, required bool) {
	f := Flag {
		flag: flag
		short_flag: short_flag
		flag_type: flag_type
		usage: usage
		required: required
	}
	if is_local == true {
		c.local_flags << f
	} else {
		c.forwardable_flags << f
	}
}

// parse_arguments - parse CLI arguments and associate them with the available flag(s).
fn (mut c Command) parse_arguments() ?bool {
	args := c.get_arguments()
	args_len := args.len
	mut idx := 0

	if args_len == 0 {
		return true
	}
	// sub_command - whether a sub-command is required to execute.
	mut sub_command_sequence := []Command{}
	for {
		arg := args[idx].str()
		// is it a flag?
		if c.is_argument_valid_flag(arg) {
			flag, is_local := c.get_flag_by_name(arg)
			// no VALID flag found for this argument value
			if flag.flag == "" && flag.short_flag == "" {
				return error("[Command][parse_arguments] invalid flag: $arg")
			}
			// key for flag
			mut key := flag.flag
			if key == "" {
				key = flag.short_flag
			}
			// value for flag
			// a SIMPLE rule is a "flag" should be associated with an immediate "value" 
			// (exception: for bool flags, the "value" is optional)
			mut value := ""
			if flag.flag_type == flag_type_bool {
				// check whether the next argument is a bool (true/false)
				if idx+1 >= args_len {
					// index out of bound check
					// no more additional value after this flag; PLUS as a bool flag, the value then must be TRUE.
					c.set_parsed_flag_value(is_local, key, true)

				} else {
					value = args[idx+1].str().to_lower()
					if value == "true" {
						c.set_parsed_flag_value(is_local, key, true)
						idx++

					} else if value == "false" {
						c.set_parsed_flag_value(is_local, key, false)
						idx++

					} else {
						// was not a bool, instead something else like a sub-command or another flag
						// hence treat this bool flag's value TRUE.
						c.set_parsed_flag_value(is_local, key, true)
					}
				}
			} else {
				idx++
				if idx >= args_len {
					// index out of bound check
					return error("[Command][parse_arguments] flag '$arg' missing a value.")
				}
				value = args[idx].str()
				// is it another flag again???
				if c.is_argument_valid_flag(value) {
					return error("[Command][parse_arguments] flag '$arg' missing a value.")
				}
				// check if the value is a sub-command
				sub_command := c.is_argument_valid_subcommand(value)
				if sub_command.name != "" {
					return error("[Command][parse_arguments] flag '$arg' missing a value. Instead a sub-command is provided.")
				}
				//sub_command_sequence << sub_command // (should not update the sub-command sequence in this case)

				// "value" is NOT a sub-command; simply a VALID value associated to the current Key.
				match flag.flag_type {
					flag_type_string { c.set_parsed_flag_value(is_local, key, value) }
					flag_type_int { 
						v := strconv.atoi(value) or {
							return error("[Command][parse_arguments] failed to convert value to 'int', reason [$err]")
						}
						c.set_parsed_flag_value(is_local, key, v) 
					}
					flag_type_i8 {
						v := strconv.atoi(value) or {
							return error("[Command][parse_arguments] failed to convert value to 'i8', reason [$err]")
						}
						c.set_parsed_flag_value(is_local, key, i8(v)) 
					}
					flag_type_bool {
						v := value.to_lower()
						if v == "true" {
							c.set_parsed_flag_value(is_local, key, true) 
						} else {
							c.set_parsed_flag_value(is_local, key, false) 
						}
					}
					flag_type_float {
						v := strconv.atof64(value)
						c.set_parsed_flag_value(is_local, key, f32(v))
					}
					flag_type_map_of_string {
						// is it in format sub_key=sub_value ?
						kv := value.split("=")
						if kv.len != 2 {
							return error("[Command][parse_arguments] failed to convert value {$value} to key-value pair. (expect format > 'key=value')")
						}
						// set the kv into the parsed-map
						c.set_parsed_flag_kv_value(is_local, key, kv[0], kv[1])
					}
					else { return error("[Command][parse_arguments] unsupported type ${flag.flag_type}") }

				} // end - match (flag.flag_type)
			} // end - if (flag.flag_type == bool)
			
		} else {
			// TODO: check the sub-command logics here...
			// should be a sub-command... if not found, then would result an error. 
			sub_command := c.is_argument_valid_subcommand(arg)
			if sub_command.name == "" {
				return error("[Command][parse_arguments] value '$arg' is not a VALID sub-command NOR a VALID flag.")
			}
			sub_command_sequence << sub_command
		}
		idx++
		if idx >= args_len {
			break
		}
	}
	// the "required" flag check
	c.is_all_required_flags_set()?
	// [debug]
	//println("## local_flags_map:\n${c.parsed_local_flags_map}")
	//println("## fwd_flags_map:\n${c.parsed_forwardable_flags_map}")
	//println("## sub_command_sequences -> $sub_command_sequence")
	return true
}

// is_all_required_flags_set - method to check whether all required flag(s) are set.
fn (c Command) is_all_required_flags_set() ?bool {
	// local flags
	for flag in c.local_flags {
		if flag.required {
			flag_key := c.build_flag_key(flag.flag, flag.short_flag)
			if (flag_key in c.parsed_local_flags_map) == false {
				return error("[Command][is_all_required_flags_set] a required local flag [${flag.flag}/${flag.short_flag}] is missing.")
			}
		}
	}
	// forwardable flags
	for flag in c.forwardable_flags {
		if flag.required {
			flag_key := c.build_flag_key(flag.flag, flag.short_flag)
			if (flag_key in c.parsed_forwardable_flags_map) == false {
				return error("[Command][is_all_required_flags_set] a required forwardable flag [${flag.flag}/${flag.short_flag}] is missing.")
			}
		}
	}
	return true
}

// is_argument_valid_flag - checks whether the [arg] is a valid flag.
// a Valid flag starts with "--" or "-".
fn (c Command) is_argument_valid_flag(arg string) bool {
	if arg.starts_with("--") || arg.starts_with("-") {
		return true
	}
	return false
}

// set_parsed_flag_value - set the provided [key]-[value] pair to the parsed-map structure.
fn (mut c Command) set_parsed_flag_value(is_local bool, key string, value Any) {
	if is_local {
		c.parsed_local_flags_map[key] = value
	} else {
		c.parsed_forwardable_flags_map[key] = value
	}
}

// set_parsed_flag_kv_value - set the [subkey]-[value] pair under the main [key] within the parsed-flag map.
fn (mut c Command) set_parsed_flag_kv_value(is_local bool, key string, subkey string, value string) {
	if is_local {
		mut f_map := map[string]string{}
		// is main [key] available???
		if key in c.parsed_local_flags_map {
			// casting... (vs match syntax)
			m := c.parsed_local_flags_map[key]
			match mut m {
				map[string]string {
					//println("##### -> ${typeof(m).name} OR ${m.type_name()}")
					m[subkey] = value
				}
				else {}
			}
		} else {
			f_map[subkey] = value
			c.parsed_local_flags_map[key] = Any(f_map)
		}
	} else {
		mut f_map := map[string]string{}
		// is main [key] available???
		if key in c.parsed_forwardable_flags_map {
			// casting... (vs match syntax)
			m := c.parsed_forwardable_flags_map[key]
			match mut m {
				map[string]string {
					//println("##### -> ${typeof(m).name} OR ${m.type_name()}")
					m[subkey] = value
				}
				else {}
			}
		} else {
			f_map[subkey] = value
			c.parsed_forwardable_flags_map[key] = Any(f_map)
		}
		//println("*** fwd has a match with $key -> ${c.parsed_forwardable_flags_map[key]}")
	}
}

// is_argument_valid_subcommand - checks whether the [arg] is referring to a valid sub-command.
fn (c Command) is_argument_valid_subcommand(arg string) Command {
	if arg == "" {
		return Command{}
	}
	for x in c.sub_commands {
		if x.name == arg {
			return x
		}
	}
	return Command{}
}

// get_flag_by_name - return the Flag that matches the [flag_name]. 
// The 2nd return value (bool) indicates whether the Flag is found inside the local-flags or not, 
// false means coming from forwardable-flags.
fn (c Command) get_flag_by_name(flag_name string) (Flag, bool) {
	mut f := Flag{}
	mut name := flag_name.str()
	// remove the -- or - prefixed
	if name.starts_with("--") {
		name = name.substr(2, name.len)
	} else if name.starts_with("-") {
		name = name.substr(1, name.len)
	}
	// search forwardable
	for x in c.forwardable_flags {
		if x.flag == name || x.short_flag == name {
			return x, false
		}
	}
	// search local (if the above is not found)
	for x in c.local_flags {
		if x.flag == name || x.short_flag == name {
			return x, true
		}
	}
	return f, true
}

// build_flag_key - return the flag key based on values provided. 
// Simple rule is if [flag] is non "", use it as key; else use [flag_short]. 
// However if both [flag] and [flag_short] are "", return "" as well, which means INVALID.
fn (c Command) build_flag_key(flag string, flag_short string) string {
	if flag == "" && flag_short == "" {
		return ""
	}
	// remove "--" or "-"
	mut f := flag.str()
	mut f_short := flag_short.str()
	if f.starts_with("--") {
		f = f.substr(2, f.len)
	}
	if f_short.starts_with("-") {
		f_short = f_short.substr(1, f_short.len)
	}
	// return long or short flag?
	if f != "" {
		return f
	}
	return f_short
}

// get_string_flag_value - return the flag's string value if valid.
pub fn (c Command) get_string_flag_value(is_local bool, flag string, flag_short string) ?string {
	// get the flag name (rule, if flag is provided use it, else use the flag_short value)
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_string_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			string { return s }
			else { return error("[Command][get_string_flag_value] local flag either not-found or the data-type is not a 'string'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			string { return s }
			else { return error("[Command][get_string_flag_value] forwardable flag either not-found or the data-type is not a 'string'.") }
		}
	}
	// this line should not be invoked by any means... though
	return error("[Command][get_string_flag_value] flag {$flag}/{$flag_short} not found.")
}

// get_int_flag_value - return the flag's int value if valid.
pub fn (c Command) get_int_flag_value(is_local bool, flag string, flag_short string) ?int {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_int_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			int { return s }
			else { return error("[Command][get_int_flag_value] local flag either not-found or the data-type is not a 'int'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			int { return s }
			else { return error("[Command][get_int_flag_value] forwardable flag either not-found or the data-type is not a 'int'.") }
		}
	}
}

// get_i8_flag_value - return the flag's i8 value if valid.
pub fn (c Command) get_i8_flag_value(is_local bool, flag string, flag_short string) ?i8 {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_i8_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			i8 { return s }
			else { return error("[Command][get_i8_flag_value] local flag either not-found or the data-type is not a 'i8'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			i8 { return s }
			else { return error("[Command][get_i8_flag_value] forwardable flag either not-found or the data-type is not a 'i8'.") }
		}
	}
}

// get_bool_flag_value - return the flag's bool value if valid.
pub fn (c Command) get_bool_flag_value(is_local bool, flag string, flag_short string) ?bool {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_bool_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			bool { return s }
			else { return error("[Command][get_bool_flag_value] local flag either not-found or the data-type is not a 'bool'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			bool { return s }
			else { return error("[Command][get_bool_flag_value] forwardable flag either not-found or the data-type is not a 'bool'.") }
		}
	}
}

// get_float_flag_value - return the flag's float value if valid.
pub fn (c Command) get_float_flag_value(is_local bool, flag string, flag_short string) ?f32 {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_float_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			f32 { return s }
			else { return error("[Command][get_float_flag_value] local flag either not-found or the data-type is not a 'float'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			f32 { return s }
			else { return error("[Command][get_float_flag_value] forwardable flag either not-found or the data-type is not a 'float'.") }
		}
	}
}

// get_map_of_string_flag_value - return the flag's map-of-string value if valid.
pub fn (c Command) get_map_of_string_flag_value(is_local bool, flag string, flag_short string) ?map[string]string {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_map_of_string_flag_value] invalid flag values, both flags are ''.")
	}
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			map[string]string { return s }
			else { return error("[Command][get_map_of_string_flag_value] local flag either not-found or the data-type is not a 'float'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			map[string]string { return s }
			else { return error("[Command][get_map_of_string_flag_value] forwardable flag either not-found or the data-type is not a 'float'.") }
		}
	}
}

// remove_flag - remove a Flag.
pub fn (mut c Command) remove_flag(is_local bool, flag string, flag_short string) bool {
	mut is_removed := false
	flag_key := c.build_flag_key(flag, flag_short)
	if is_local {
		// remove from []Flag repository
		for idx, f in c.local_flags {
			if f.flag == flag_key || f.short_flag == flag_key {
				c.local_flags.delete(idx)
				is_removed = true
				break
			}
		}
		// also remove from parsed map[string]Any repository
		if is_removed && (flag_key in c.parsed_local_flags_map) {
			c.parsed_local_flags_map.delete(flag_key)
		}

	} else {
		// remove from []Flag repository
		for idx, f in c.forwardable_flags {
			if f.flag == flag_key || f.short_flag == flag_key {
				c.forwardable_flags.delete(idx)
				is_removed = true
				break
			}
		}
		// also remove from parsed map[string]Any repository
		if is_removed && (flag_key in c.parsed_forwardable_flags_map) {
			c.parsed_forwardable_flags_map.delete(flag_key)
		}
	}
	return is_removed
}

// write_to_output - write contents to the output stream. Default is stdout.
pub fn (mut c Command) write_to_output(content []byte) ?int {
	// [doc] convert string to []byte -> https://modules.vlang.io/#string.bytes
	// example. "hello world".bytes() -> []byte

	//return c.stdout.write(content)
	return c.out_buffer.write(content)
}

// [future]
pub fn (mut c Command) read_all_from_stream() []byte {
	// TODO: test + impl set_output() AND read_all_from_stream()
	// read by supplying a buffer -> https://modules.vlang.io/os.html#File.read
	// append the content by -> https://modules.vlang.io/strings.html#Builder 
	// actual write fn -> https://modules.vlang.io/strings.html#Builder.write 
	// convert to string -> https://modules.vlang.io/strings.html#Builder.str
	// convert from []byte to string -> string(b_content)
	
	/*
	mut data := strings.new_builder(0)

	mut buf := []byte{ len: 1024, cap: 1024 }
	for {
		num := c.stdout.read(mut buf) or {
			return "ERROR in reading stream data, $err".bytes()
		} 
		if num == 0 || num == -1 {
			// end of stream met...
			break
		} else {
			data.write(buf[0..num]) or {
				return "ERROR in appending stream data, $err".bytes()
			}
		}
	}
	return data.str().bytes()
	*/

	// [debug]
	//println("#$#$#$#$ -> ${c.out_buffer.len} vs ${c.out_buffer.cap}")
	mut b_content := c.out_buffer.to_string(false).bytes()
	// remove leading + trailing '\0'
	// handling trailing '\0'
	mut idx := b_content.len - 1
	mut has_zero_char := false
	for {
		if idx == -1 {
			break
		}
		if b_content[idx] != `\0` {
			break
		}
		has_zero_char = true
		idx--
	}
	if has_zero_char {
		b_content = b_content[0..idx+1]
	}
	// handling leading '\0'
	has_zero_char = false
	idx = 0
	for {
		if idx == b_content.len {
			break
		}
		if b_content[idx] != `\0` {
			break
		}
		has_zero_char = true
		idx++
	}
	if has_zero_char {
		b_content = b_content[idx..b_content.len]
	}
	// remove trailing `\n` (only remove once)
	/*
	idx = b_content.len-1
	if b_content[idx] == `\n` {
		b_content = b_content[0..b_content.len-1]
	}
	*/
	return b_content
}

// TODO: a way to forward the forwardable flags to the sub-commands ... e.g. calling a fn (parent_command.get_parsed_forwardable_flags)
// -> check if "parent" reference is valid, if so, call the grand-parent-cmd.get_parsed_forwardable_flags();
// -> merge all parent level parsed forwardable flag(s) and done~


// TODO: isFlagSet(flagName)