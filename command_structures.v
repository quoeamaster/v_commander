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

// Command - a structure describing a CLI command.
pub struct Command {
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
	stdout os.File

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

// add_commands - add the provided sub-command(s), if any.
pub fn (mut c Command) add_commands(cmds ...Command) {
	for cmd in cmds {
		c.sub_commands << cmd
	}
}

// run - set the provided [handler] to the CLI and execute it. [run] provides the core functionality for this CLI.
pub fn (mut c Command) run(handler ...fn(cmd &Command, args []string) ?i8) ?i8 {
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
	// [debug]
	//println("## local_flags_map:\n${c.parsed_local_flags_map}")
	//println("## fwd_flags_map:\n${c.parsed_forwardable_flags_map}")
	//println("## sub_command_sequences -> $sub_command_sequence")
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

// e.g. args -> --config /var/app.config -E age=18 --trace
//  outcome would be
//  - config:"/var/app.config"
//  - E (map or array) age:18
//  - trace:true

// e.g. args + sub-command -> list --config /var/app.config -E age=18 --trace
//  outcome would be
//  - config:"/var/app.config"
//  - E (map or array) age:18
//  - trace:true
//  subcommand -> list (checks through the c.sub_commands.name attribute); "list" could be at any position as well.
//   if "list" was not a valid sub-command (not exists), will throw error.
//   if "list" is VALID, will let the sub-command to do the parsing of local-flag(s); 
//    remember forwardable-flag(s) MUST be handled by the parent command and pass to the sub-command(s).


/*  TODO: handle the parse method before implementing the get_xxx_flag_value... since the arguments map has not been handled...

pub fn (c Command) get_string_flag_value(is_local bool, flag string, short_flag string) ?string {
	if is_local == true {
		for f in c.local_flags {
			if f.flag == flag || f.short_flag == short_flag {
				return 
			}
		}
	} else {

	}
	return error("[Command][get_string_flag_value] flag {$flag}/{$short_flag} not found.")
}
*/

// TODO: set flags (local vs forwardable) no varp variant, instead use getFlagXXXValue()
// TODO: isFlagSet(flagName)
// TODO: getFlagBoolValue() getFlagStringValue()