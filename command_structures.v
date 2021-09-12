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
	sub_commands []&Command
	// sub_command_sequence - the sequence in which a sequence of sub-command(s) are involved. 
	// This sequence affects which sub-command would be triggred to run its run_handler.
	sub_command_sequence []Command
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
	// run_handler - a function to handle business logics for this CLI - the core function. Returns an integer status.
	run_handler fn(cmd &Command, args []string) ?i8
	// help_handler - a function to produce the customized help message. If provided, the default help message generation 
	// would be replaced by this function.
	help_handler fn(&Command) string = default_help_handler
}

// default_help_handler - default help generator.
fn default_help_handler(mut c &Command) string {
	mut s := new_string_buffer(128)
	// change the return object to "reference" / pointer.
	/* 
	// [deprecated] should not need to parse arguments again...
	mut target_cmd := c.parse_arguments() or {
		// error, assume the current command (c) would be a clue to how to use this CLI / Command
		s.write_string("${red(err.msg)}\n")
		//(*c) // -> if return type is Command then (*c)
		c
	}
	*/
	mut target_cmd := c
	// short description
	if target_cmd.short_description != "" {
		s.write_string("${target_cmd.short_description}\n\n")
	}
	// example if any
	mut v := target_cmd.description
	if v != "" {
		s.write_string("${v}\n\n")
	}
	// usage
	s.write_string("Usage:\n")
	mut cmd_hierarchy := target_cmd.name
	mut c_cmd := target_cmd
	for {
		//println("[debug] current-name: ${c_cmd.name}, parent-name: ${c_cmd.parent.name}")
		if c_cmd.parent.name != empty_command.name {
			cmd_hierarchy = "${c_cmd.parent.name} ${cmd_hierarchy}"
			c_cmd = c_cmd.parent
		} else {
			break
		}
	} // end - for
	v = "   ${cmd_hierarchy}"
	if target_cmd.sub_commands.len > 0 {
		v = "${v} [command]"
	}
	if target_cmd.local_flags.len > 0 || target_cmd.forwardable_flags.len > 0 {
		v = "${v} [flag]"
	}
	s.write_string("${v}\n\n")
	// sub-commands
	if target_cmd.sub_commands.len > 0 {
		s.write_string("Available Commands:\n")
		for x in target_cmd.sub_commands {
			s.write_string("   ${x.name:-8}          ${x.short_description}\n")
		} // end - for
		s.write_string("\n")
	}

	// flags
	if target_cmd.local_flags.len > 0 {
		s.write_string("Flags:\n")
		create_help_for_flags(target_cmd.local_flags, mut &s)
		s.write_string("\n")
	}
	if target_cmd.forwardable_flags.len > 0 {
		s.write_string("Forwardable Flags:\n")
		create_help_for_flags(target_cmd.forwardable_flags, mut &s)
	}
	// sub-command help
	if target_cmd.sub_commands.len > 0 {
		s.write_string('\nUse "${cmd_hierarchy} [command] --help" for more information about a command.\n')
	}
	return s.to_string(false)
} 

// create_help_for_flags - helper method to build the flag's help documentation.
fn create_help_for_flags(flags []Flag, mut s &Stringbuffer) {
	for x in flags {
		mut s_flag := x.short_flag
		if s_flag != "" {
			s_flag = "-"+s_flag+","
		} else {
			s_flag = " "
		}
		mut l_flag := x.flag
		if l_flag != "" {
			l_flag = "--"+l_flag
		}
		// convert type to string value
		mut type_name := "[string]"
		match x.flag_type {
			flag_type_bool { type_name = "[bool]"}
			flag_type_float { type_name = "[float]" }
			flag_type_i8 { type_name = "[int 8bit]" }
			flag_type_int { type_name = "[int]" }
			flag_type_map_of_string { type_name = "[key=value]" }
			else { "" }
		}
		mut flag_attr := "${type_name}"
		if x.required {
			flag_attr = "${flag_attr} REQUIRED"
		}
		s.write_string("   ${s_flag:-3} ${l_flag:-12} ${flag_attr:-20}    ${x.usage}\n")
	} // end - for
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
	// merge the forwardable flag(s)
	c.merge_with_parent_forwardable_flags()
	// add back the mandatory "--help|-H" flag
	c.add_forwardable_help_flag()
	c.merge_with_parent_forwardable_flag_map()
	
	// run the args parsing before trigger the handler
	mut target_command := c.parse_arguments() or {
		return err
	}
	// should we just run the help_handler instead of execution???
	if target_command.is_flag_set(false, "help", "H") {
		help_msg := target_command.help_handler(target_command)
		// so that the stream is still available for debug purpose
		target_command.out_buffer.write_string(help_msg)
			target_command.stdout.write(help_msg.bytes()) or {
			return error("[Command][run] error in writing output to stdout, reason: $err")
		}
		return i8(status_ok)
	}

	mut status := i8(status_ok)
	// execute the run_handler
	status = target_command.run_handler(target_command, c.get_arguments()) or {
		return error("[Command][run] error found, reason: $err")
	}

	// target_command will take over all the rest of the operation.
	// flush output to stdout
	mut stream := target_command.stdout
	// [BUG] ?? required a newline or `\0` to delimited the end of a string... c style null-delimited string.
	mut s_content := target_command.out_buffer.to_string(false) + "\n"
	if s_content.len > 1 {
		stream.write(s_content.bytes()) or {
			return error("[Command][run] error in writing output to stdout, reason: $err")
		}
	}

	// [bug]?? to make sure the invoking Command has the same output content...
	if target_command.out_buffer.len > 0 {
		c.out_buffer.write(target_command.out_buffer.to_string(false).bytes()) or {
			return error("[Command][run] failed to sync the output buffer's content back to the Command, reason: ${err}.")
		}
	}
	return status
}

// add_forwardable_help_flag - add the missing but mandatory "help" forwardable flag.
fn (mut c Command) add_forwardable_help_flag() {
	// add a "--help|-H" by default
	fwd_help := Flag{
		flag: "help",
		short_flag: "H",
		flag_type: flag_type_bool,
		usage: "display the corresponding help message for a commamd.",
		required: false,
	}
	// de-duplicate
	mut found := false
	for x in c.forwardable_flags {
		// if 100% identical -> add back this clause '&& x.short_flag == fwd_help.short_flag'
		if x.flag == fwd_help.flag  {
			found = true
			break
		}
	}
	if !found {
		c.forwardable_flags << fwd_help
	}
}

fn (mut c Command) parse_arguments() ?&Command {
	// [design]
	// 1. parse all possible flags and sub-commands (no validation yet)
	//		c.is_argument_valid_subcommand(string)
	//		c.is_argument_valid_flag(string)
	// 	-> eventually a Map of Parsed_flag(s) ... iterate and check whether any parsed_flag is INVALID...
	//
	// 2. if sub-commands available, need to parse the above flags into different levels of the sub-commands 
	//    (the lowest level - grandchild etc) would have the highest preference on setting the flag values.
	//    grandchild > child > parent (preference in setting flags)
	//    c.merge_with_parent_forwardable_flag_map()
	//    c.merge_with_parent_forwardable_flags() 
	//		then decided how to parse all the values available.
	//
	// 3. once flags done setting; pass the execution to the correct command / sub-command -> execute its run_handler.
	//    decision made by comparing the 
	//    c.sub_command_sequence()
	
	args := c.get_arguments()
	args_len := args.len
	mut idx := 0
	mut parsed_flags_map := map[string]Parsed_flag{}
	mut cmd_name := c.name

	if args_len == 0 {
		// nothing to parse, return true -> all valid
		return c
	}
	// sub_command - whether a sub-command is required to execute. (reset)
	c.sub_command_sequence = []Command{}
	for {
		// 1. parse all possible sub-commands and flag(s) (no validation yet) -> sub-commands are the 1st priority, then flag(s).
		//		c.is_argument_valid_subcommand(string)
		//		c.is_argument_valid_flag(string)
		// 	-> eventually a Map of Parsed_flag(s) ... iterate and check whether any parsed_flag is INVALID...
		arg := args[idx].str()
		sub_cmd := c.is_argument_valid_subcommand(arg)
		// a valid sub-command
		if sub_cmd.name != "" {
			c.sub_command_sequence << sub_cmd

		} else {
			// not a sub-command, the only valid option is a FLAG
			if c.is_argument_valid_flag(arg) {
				// edge case, already is the last argument... treat it as a bool flag...
				if (idx+1) >= args_len {
					p_flag := Parsed_flag{
						name: arg,
						value_in_string: "true",
						possible_bool_type: true
					}
					parsed_flags_map[arg] = p_flag
					break
				}
				// try to get the associated value next to the flag
				// the next "value" -> sub=command or a flag... then assume this parsed_flag is a "bool"
				value := args[idx+1].str()
				is_sub_command := c.is_argument_valid_subcommand(value)
				is_flag := c.is_argument_valid_flag(value)
				// --flag {sub-command} -> --flag (bool, true)
				// --flag {--anotherFlag} -> --flag (bool, true)
				// --flag {false|true} -> --flag (bool, false|true)
				// --flag {unknown} -> --flag (non-bool, unknown) -> handled as "--flag=unknown"
				if !is_flag && (is_sub_command.name != "") {
					// a. next value is a VALID subcommand
					// key -> arg could be --flag or -F, will parse this at later stage in this fn.
					p_flag := Parsed_flag{
						name: arg,
						value_in_string: "true",
						possible_bool_type: true
					}
					parsed_flags_map[arg] = p_flag
					// consumed the next argument, idx++
					c.sub_command_sequence << is_sub_command
					idx++
				} else if is_flag {
					// b. next value is a valid flag.
					p_flag := Parsed_flag{
						name: arg,
						value_in_string: "true",
						possible_bool_type: true
					}
					parsed_flags_map[arg] = p_flag
					// let the next iteration handles the parsing logic
				} else if value == "true" || value == "false" {
					// c. next value is a bool value.
					p_flag := Parsed_flag{
						name: arg,
						value_in_string: value,
						possible_bool_type: true
					}
					parsed_flags_map[arg] = p_flag
					// consumed this argument, hence idx++
					idx++
				} else {
					// d. assume next value is a valid associated to this flag.
					// validation not done at this phase, so just accept the parsed value for the moment.
					p_flag := Parsed_flag{
						name: arg,
						value_in_string: value,
						possible_bool_type: false
					}
					parsed_flags_map[arg] = p_flag
					// consumed this argument, hence idx++
					idx++
				}
			} else {
				return error("[Command][parse_arguments] invalid value, [$arg] is not a valid sub-command NOR a valid flag.")
			}
		}
		idx++
		if idx >= args_len {
			// all arguments parsed
			break
		}
	}
	// 2. if sub-commands available, need to parse the above flags into different levels of the sub-commands 
	//    (the lowest level - grandchild etc) would have the highest preference on setting the flag values.
	//    grandchild > child > parent (preference in setting flags)
	//    c.merge_with_parent_forwardable_flag_map()
	//    c.merge_with_parent_forwardable_flags() 
	//		then decided how to parse all the values available.
	//
	mut target_command := &c
	if c.sub_command_sequence.len > 0 {
		// whether the sub command sequences are valid
		// example. course.register.update is the sequence; so would need to check whether
		// course has register as sub-command AND
		// register has update as sub-command.
		
		// find the target_command based on the sequences (also if the sequence is incorrect i.e. sub-commmand not found... throw error)
		for _, cmd_seq in c.sub_command_sequence {
			mut found := false
			for _, current_cmd in target_command.sub_commands {
				// [debug]
				//println("[debug] seqname: $cmd_seq.name vs subcmd name: $current_cmd.name")
				if current_cmd.name == cmd_seq.name {
					target_command = current_cmd
					found = true
					break
				}
			}
			if !found {
				mut seq_str := ""
				for _, v in c.sub_command_sequence {
					if seq_str.len > 0 {
						seq_str += "."
					}
					seq_str += "$v.name"
				}
				// build the cmd sequence label
				if c.sub_command_sequence.len > 0 {
					cmd_name = c.sub_command_sequence[0].name
				}
				info_msg := yellow('Use "${cmd_name} [command] --help" for more information about a command.') 
				return error('[Command][parse_arguments] the command sequence [ $seq_str ] to be executed is not VALID, please check the documentations on how to use the Command. ${info_msg}')
			}
		}
		// inherit all parent level fwd flag(s) first
		target_command.merge_with_parent_forwardable_flags()
	}
	// set local flags on target_cmd
	// [bug] ?? seems need to reset the parsed map(s).
	target_command.parsed_local_flags_map = map[string]Any{}
	target_command.parsed_forwardable_flags_map = map[string]Any{}
	for l_flag in target_command.local_flags {
		flag_key := c.build_flag_key(l_flag.flag, l_flag.short_flag)

		for _, p_flag in parsed_flags_map {
			mut key := p_flag.name.str()
			if key.starts_with("--") {
				key = key.substr(2, key.len)
			} else if key.starts_with("-") {
				key = key.substr(1, key.len)
			}
			// [debug]
			//println("[debug] parsed_flag -> key=$key matching $l_flag.flag or $l_flag.short_flag")
			// set
			if l_flag.flag == key || l_flag.short_flag == key {
				// add back the possible_bool_type check... 
				// e.g. if parsed_flags_map -> p_flag.possible_bool_type == true BUT l_flag.flag_type != flag_type_bool => error(incompatible type)
				if l_flag.flag_type != flag_type_bool && p_flag.possible_bool_type {
					info_msg := yellow('Use "${cmd_name} [command] --help" for more information about a command.') 
					return error("[Command][parse_arguments] flag [$l_flag.flag/$l_flag.short_flag] is non bool-typed, but the provided value for this flag is a bool valued [$p_flag.value_in_string]. ${info_msg}")
				}
				target_command.set_parsed_flag_value_by_string_value(true, flag_key, l_flag.flag_type, 
					p_flag.value_in_string)?
				// [debug]
				//println("[debug] set~ $key -> $target_command.parsed_local_flags_map")
			}
		}
	}
	// set fwd flags on target_cmd
	for f_flag in target_command.forwardable_flags {
		flag_key := c.build_flag_key(f_flag.flag, f_flag.short_flag)

		for _, p_flag in parsed_flags_map {
			mut key := p_flag.name.str()
			if key.starts_with("--") {
				key = key.substr(2, key.len)
			} else if key.starts_with("-") {
				key = key.substr(1, key.len)
			}
			// set
			if f_flag.flag == key || f_flag.short_flag == key {
				if f_flag.flag_type != flag_type_bool && p_flag.possible_bool_type {
					info_msg := yellow('Use "${cmd_name} [command] --help" for more information about a command.') 
					return error("[Command][parse_arguments] flag [$f_flag.flag/$f_flag.short_flag] is non bool-typed, but the provided value for this flag is a bool valued [$p_flag.value_in_string]. ${info_msg}")
				}
				target_command.set_parsed_flag_value_by_string_value(false, flag_key, f_flag.flag_type, 
					p_flag.value_in_string)?
			}
		}
	}
	target_command.merge_with_parent_forwardable_flag_map()
	// [debug]
	/*
	println("\n*!* after merge parsed_flags map -> $parsed_flags_map")
	println("*!* after merge args -> $args")
	println("*!* after merge map[string]Any -> $target_command.parsed_forwardable_flags_map")
	println("*!* after merge map[string]Any local -> $target_command.parsed_local_flags_map")
	//println("*!* after merge map[string]Any c -> $c.parsed_forwardable_flags_map")
	//println("*!* after merge map[string]Any local c -> $c.parsed_local_flags_map")
	println("*!* after merge flag[] -> $target_command.forwardable_flags")
	println("*!* after merge flag[] local -> $target_command.local_flags")
	//println("#!# sub_commands -> $c.sub_command_sequence")
	*/

	// check if all "required" flags set.
	target_command.is_all_required_flags_set()?
	// check whether any unknown flags parsed.
	target_command.has_any_unknown_flags(parsed_flags_map)?

	return &target_command
}

// set_parsed_flag_value_by_string_value - set the provided flag's value to the corresponding parsed flag map.
fn (mut c Command) set_parsed_flag_value_by_string_value(is_local bool, flag_key string, flag_type i8, v_str string) ?bool {
	// [debug]
	//println("[debug] {$is_local} $flag_key -> type $flag_type -> $v_str")
	if flag_type == flag_type_string {
		c.set_parsed_flag_value(is_local, flag_key, v_str)

	} else if flag_type == flag_type_int {
		v := strconv.atoi(v_str) or {
			return error("[Command][set_parsed_flag_value_by_string_value] invalid int value provided [$v_str] for ${flag_key}.")
		}
		c.set_parsed_flag_value(is_local, flag_key, v)

	} else if flag_type == flag_type_i8 {
		v := strconv.atoi(v_str) or {
			return error("[Command][set_parsed_flag_value_by_string_value] invalid i8 value provided [$v_str] for ${flag_key}.")
		}
		c.set_parsed_flag_value(is_local, flag_key, i8(v))

	} else if flag_type == flag_type_bool {
		v := v_str.to_lower()
		if v == "true" {
			c.set_parsed_flag_value(is_local, flag_key, true)
		} else if v == "false" {
			c.set_parsed_flag_value(is_local, flag_key, false)
		} else {
			return error("[Command][set_parsed_flag_value_by_string_value] invalid bool value provided [$v_str] for ${flag_key}.")
		}
		// [debug]
		//println("[debug] $flag_key -> ${c.parsed_forwardable_flags_map[flag_key]}")
	} else if flag_type == flag_type_float {
		v := strconv.atof64(v_str)
		c.set_parsed_flag_value(is_local, flag_key, f32(v))

	} else if flag_type == flag_type_map_of_string {
		// is it in format sub_key=sub_value ?
		kv := v_str.split("=")
		if kv.len != 2 {
			return error("[Command][set_parsed_flag_value_by_string_value] invalid float value provided [$v_str] for ${flag_key}. (expect format > 'key=value').")
		}
		// set the kv into the parsed-map
		c.set_parsed_flag_kv_value(is_local, flag_key, kv[0], kv[1])

	} else {
		return error("[Command][set_parsed_flag_value_by_string_value] unsupported type ${flag_type}.")
	}
	return true
}

// has_any_unknown_flags - checks whether any unknown flag(s) available. Return an error once met any unknown flag.
fn (c Command) has_any_unknown_flags(parsed_flags_map map[string]Parsed_flag) ?bool {
	for k, _ in parsed_flags_map {
		mut key := k.str()
		//mut is_long_flag := true
		mut found := false

		if key.starts_with("--") {
			key = key.substr(2, key.len)
		} else if key.starts_with("-") {
			//is_long_flag = false
			key = key.substr(1, key.len)
		}
		// check whether it is on the local flags
		for _, l_v in c.local_flags {
			if l_v.flag == key || l_v.short_flag == key {
				found = true
				break
			}
		}
		if found {
			continue
		}
		// check whether it is on the fwd flags
		for _, f_v in c.forwardable_flags {
			if f_v.flag == key || f_v.short_flag == key {
				found = true
				break
			}
		}
		if found {
			continue
		}
		// if reach here, means the "key" not found in both parsed flags
		info_msg := yellow('Use "${c.name} [command] --help" for more information about a command')
		return error("[Command][has_any_unknown_flags] unknown key ${k}. ${info_msg}")
	}
	return true
}

// help - set the provided [handler] to the CLI and execute it. [help] facilitates a customized help message if necessary.
pub fn (mut c Command) help(handler ...fn(cmd &Command) string) string {
	// find the correct sub-command to show help
	mut target_cmd := c.parse_arguments() or {
		// TODO: integrate with the default help fn instead...
		return "[Command][help] parse arguments failed, reason: ${err}"
	}

	if handler.len != 0 {
		target_cmd.help_handler = handler[0]
	}
	// execute
	return target_cmd.help_handler(target_cmd)
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

// is_all_required_flags_set - method to check whether all required flag(s) are set.
fn (c Command) is_all_required_flags_set() ?bool {
	info_msg := yellow('Use "${c.name} [command] --help" for more information about a command')
	// local flags
	for flag in c.local_flags {
		if flag.required {
			flag_key := c.build_flag_key(flag.flag, flag.short_flag)
			if (flag_key in c.parsed_local_flags_map) == false {
				return error("[Command][is_all_required_flags_set] a required local flag [${flag.flag}/${flag.short_flag}] is missing. ${info_msg}")
			}
		}
	}
	// forwardable flags
	for flag in c.forwardable_flags {
		if flag.required {
			flag_key := c.build_flag_key(flag.flag, flag.short_flag)
			if (flag_key in c.parsed_forwardable_flags_map) == false {
				return error("[Command][is_all_required_flags_set] a required forwardable flag [${flag.flag}/${flag.short_flag}] is missing. ${info_msg}")
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
	//println("[debug] map set -> $key=$value $c.name -> $c.parsed_local_flags_map and $c.parsed_forwardable_flags_map")
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

// get_all_subcommand_names - return the valid subcommand names recursively.
fn (c Command) get_all_subcommand_names(parent_cmd_name string) map[string]string {
	// value -> string -> hierarchy of this sub-command.
	mut names := map[string]string{}
	for x in c.sub_commands {
		names[x.name] = parent_cmd_name+"."+(x.name)
		// from the underneath subcommand
		sub_names := x.get_all_subcommand_names(parent_cmd_name+"."+(x.name))
		// [debug]
		//println("[debug] $sub_names for $x.name -> $x.sub_commands")

		// merge if non empty
		if sub_names.len > 0 {
			for key, _ in sub_names {
				names[key] = parent_cmd_name+"."+(x.name)+"."+key
			}
		}
	}
	return names
}

// is_argument_valid_subcommand - checks whether the [arg] is referring to a valid sub-command.
fn (c Command) is_argument_valid_subcommand(arg string) &Command {
	if arg == "" {
		return &Command{}
	}
	// a valid sub-command?? (recursively)
	m := c.get_all_subcommand_names(c.name)
	// [debug]
	//println("** [debug] $m\n_ $arg _")
	mut target_command := Command{}
	if arg in m {
		target_command = c
		cmd_hierarchy := m[arg].split(".")
		for i, c_name in cmd_hierarchy {
			// skip the 1st cmd hierarchy as its the parent's name in general
			if i == 0 {
				if c.name != c_name {
					//return error("[Command][parse_arguments] seems the parent cmd is NOT correct, expecting [$c_name], actual [$c.name]")
					return &Command{}
				}
				continue
			}
			mut found := false
			for current_cmd in target_command.sub_commands {
				// [debug]
				//println("* cur vs c_name => ${current_cmd.name} vs $c_name")
				if current_cmd.name == c_name {
					target_command = current_cmd
					found = true
					break
				}
			}
			if !found {
				// not found~~~ impossible (would say)
				println("not found???")
				return &Command{}
			}
		} // end - for (cmd_hierarchy)
	}
	return &target_command
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
	// return the flag object and where it was found (local or fwd)
	flag_obj, is_local_flag := c.get_flag_by_name(flag_name)
	mut is_valid_flag_obj := true
	if flag_obj.flag == "" && flag_obj.short_flag == "" {
		is_valid_flag_obj = false
	}

	// NOT found, key is valid but no entry set
	if !is_valid_flag_obj {
		return error("[Command][get_string_flag_value] invalid flag, this flag is not configured.")
	}
	// a. either NOT found or located at the wrong flag type (local vs fwd)
	if is_local_flag != is_local {
		return error("[Command][get_string_flag_value] this flag is not configured as a [local == $is_local] flag.")
	}
	
	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			string { return s }
			else { 
				if !flag_obj.required {
					// return a DEFAULT value based on the type (in this case, string)
					return ""
				}
				return error("[Command][get_string_flag_value] local flag either not-found or the data-type is not a 'string'.") 
			}
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			string { return s }
			else { 
				if !flag_obj.required {
					// return a DEFAULT value based on the type (in this case, string)
					return ""
				}
				return error("[Command][get_string_flag_value] forwardable flag either not-found or the data-type is not a 'string'.") 
			}
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
	// return the flag object and where it was found (local or fwd)
	flag_obj, is_local_flag := c.get_flag_by_name(flag_name)
	mut is_valid_flag_obj := true
	if flag_obj.flag == "" && flag_obj.short_flag == "" {
		is_valid_flag_obj = false
	}

	// NOT found, key is valid but no entry set
	if !is_valid_flag_obj {
		return error("[Command][get_int_flag_value] invalid flag, this flag is not configured.")
	}
	// a. either NOT found or located at the wrong flag type (local vs fwd)
	if is_local_flag != is_local {
		return error("[Command][get_int_flag_value] this flag is not configured as a [local == $is_local] flag.")
	}

	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			int { return s }
			else { 
				if !flag_obj.required {
					return 0
				}
				return error("[Command][get_int_flag_value] local flag either not-found or the data-type is not a 'int'.") 
			}
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			int { return s }
			else { 
				if !flag_obj.required {
					return 0
				}
				return error("[Command][get_int_flag_value] forwardable flag either not-found or the data-type is not a 'int'.") 
			}
		}
	}
}

// get_i8_flag_value - return the flag's i8 value if valid.
pub fn (c Command) get_i8_flag_value(is_local bool, flag string, flag_short string) ?i8 {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_i8_flag_value] invalid flag values, both flags are ''.")
	}
	// return the flag object and where it was found (local or fwd)
	flag_obj, is_local_flag := c.get_flag_by_name(flag_name)
	mut is_valid_flag_obj := true
	if flag_obj.flag == "" && flag_obj.short_flag == "" {
		is_valid_flag_obj = false
	}

	// NOT found, key is valid but no entry set
	if !is_valid_flag_obj {
		return error("[Command][get_i8_flag_value] invalid flag, this flag is not configured.")
	}
	// a. either NOT found or located at the wrong flag type (local vs fwd)
	if is_local_flag != is_local {
		return error("[Command][get_i8_flag_value] this flag is not configured as a [local == $is_local] flag.")
	}

	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			i8 { return s }
			else { 
				if !flag_obj.required {
					return i8(0)
				}
				return error("[Command][get_i8_flag_value] local flag either not-found or the data-type is not a 'i8'.") 
			}
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			i8 { return s }
			else { 
				if !flag_obj.required {
					return i8(0)
				}
				return error("[Command][get_i8_flag_value] forwardable flag either not-found or the data-type is not a 'i8'.") 
			}
		}
	}
}

// get_bool_flag_value - return the flag's bool value if valid.
pub fn (c Command) get_bool_flag_value(is_local bool, flag string, flag_short string) ?bool {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_bool_flag_value] invalid flag values, both flags are ''.")
	}
	// return the flag object and where it was found (local or fwd)
	flag_obj, is_local_flag := c.get_flag_by_name(flag_name)
	mut is_valid_flag_obj := true
	if flag_obj.flag == "" && flag_obj.short_flag == "" {
		is_valid_flag_obj = false
	}

	// NOT found, key is valid but no entry set
	if !is_valid_flag_obj {
		return error("[Command][get_bool_flag_value] invalid flag, this flag is not configured.")
	}
	// a. either NOT found or located at the wrong flag type (local vs fwd)
	if is_local_flag != is_local {
		return error("[Command][get_bool_flag_value] this flag is not configured as a [local == $is_local] flag.")
	}

	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			bool { return s }
			else { 
				if !flag_obj.required {
					return false
				}
				return error("[Command][get_bool_flag_value] local flag either not-found or the data-type is not a 'bool'.") 
			}
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			bool { return s }
			else { 
				if !flag_obj.required {
					return false
				}
				return error("[Command][get_bool_flag_value] forwardable flag either not-found or the data-type is not a 'bool'.") 
			}
		}
	}
}

// get_float_flag_value - return the flag's float value if valid.
pub fn (c Command) get_float_flag_value(is_local bool, flag string, flag_short string) ?f32 {
	flag_name := c.build_flag_key(flag, flag_short)
	if flag_name == "" {
		return error("[Command][get_float_flag_value] invalid flag values, both flags are ''.")
	}
	// return the flag object and where it was found (local or fwd)
	flag_obj, is_local_flag := c.get_flag_by_name(flag_name)
	mut is_valid_flag_obj := true
	if flag_obj.flag == "" && flag_obj.short_flag == "" {
		is_valid_flag_obj = false
	}

	// NOT found, key is valid but no entry set
	if !is_valid_flag_obj {
		return error("[Command][get_float_flag_value] invalid flag, this flag is not configured.")
	}
	// a. either NOT found or located at the wrong flag type (local vs fwd)
	if is_local_flag != is_local {
		return error("[Command][get_float_flag_value] this flag is not configured as a [local == $is_local] flag.")
	}

	// search for the flag_name from the parsed-flag repositories
	if is_local == true {
		s := c.parsed_local_flags_map[flag_name]
		match s {
			f32 { return s }
			else {
				if !flag_obj.required {
					return f32(0)
				} 
				return error("[Command][get_float_flag_value] local flag either not-found or the data-type is not a 'float'.") 
			}
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			f32 { return s }
			else { 
				if !flag_obj.required {
					return f32(0)
				}
				return error("[Command][get_float_flag_value] forwardable flag either not-found or the data-type is not a 'float'.") 
			}
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
			else { return error("[Command][get_map_of_string_flag_value] local flag either not-found or the data-type is not a 'map of string'.") }
		}
	} else {
		s := c.parsed_forwardable_flags_map[flag_name]
		match s {
			map[string]string { return s }
			else { return error("[Command][get_map_of_string_flag_value] forwardable flag either not-found or the data-type is not a 'map of string'.") }
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

// read_all_from_stream - read everything from the underlying output-stream.
pub fn (mut c Command) read_all_from_stream() []byte {
	// [reference links]
	// read by supplying a buffer -> https://modules.vlang.io/os.html#File.read
	// append the content by -> https://modules.vlang.io/strings.html#Builder 
	// actual write fn -> https://modules.vlang.io/strings.html#Builder.write 
	// convert to string -> https://modules.vlang.io/strings.html#Builder.str
	// convert from []byte to string -> string(b_content)

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
	return b_content
}

// merge_with_parent_forwardable_flag_map - return the merged forwardable_flag(s) map.
fn (mut c Command) merge_with_parent_forwardable_flag_map() map[string]Any {
	// [design]
	// a way to forward the forwardable flags to the sub-commands ... e.g. calling a fn (parent_command.get_parsed_forwardable_flags)
	// -> check if "parent" reference is valid, if so, call the grand-parent-cmd.get_parsed_forwardable_flags();
	// -> merge all parent level parsed forwardable flag(s) and done~

	// non "empty" parent
	if c.parent.name != empty_command.name {
		// udpate the parsed flag map
		m := c.parent.merge_with_parent_forwardable_flag_map()
		// combine with the current forwarable_flags.
		for k, v in m {
			// only add missing key-value pair(s), would not override any existing values.
			if !(k in c.parsed_forwardable_flags_map) {
				c.parsed_forwardable_flags_map[k] = v
			}
		} // end - for (parent.forwardable_flags)
	}
	// no matter whether any parent or grandparent is available, would return the current cmd's parsed forwardable flag map.
	return c.parsed_forwardable_flags_map
}

// merge_with_parent_forwardable_flags - return the merged forwardable_flag(s) array.
fn (mut c Command) merge_with_parent_forwardable_flags() []Flag {
	// non "empty" parent
	if c.parent.name != empty_command.name {
		// return the merged parent, grandparent []Flag(s)
		m := c.parent.merge_with_parent_forwardable_flags()
		// combine with the current forwarable_flags.
		for _, flag in m {
			mut found := false
			for _, flag_current in c.forwardable_flags {
				if flag_current.flag == flag.flag || flag_current.short_flag == flag.short_flag {
					found = true
					break
				}
			}
			// missing this forwardable flag from the parent(s).
			if !found {
				c.forwardable_flags << flag
			}
		} // end - for (flags within the parent []Flag)
	}
	// no matter whether any parent or grandparent is available, would return the current cmd's parsed forwardable flag array.
	return c.forwardable_flags
}

// is_flag_set - checks whether the flag is set for this CLI, remember that a flag could be non-REQUIRED and hence no-need to be SET.
// The bool indicates whether the flag is set.
pub fn (c Command) is_flag_set(is_local bool, flag string, short_flag string) bool {
	flag_name := c.build_flag_key(flag, short_flag)
	if flag_name == "" {
		return false
		//return error("[Command][is_flag_set] invalid flag values, both flags are ''.")
	}
	if is_local {
		// [debug]
		//println("&&& inside local, $c.parsed_local_flags_map\n$c.parsed_forwardable_flags_map")
		for k, _ in c.parsed_local_flags_map {
			// [debug]
			//println("&&& key $flag_name -> $k")
			if k == flag_name {
				return true
			}
		}
	} else {
		for k, _ in c.parsed_forwardable_flags_map {
			if k == flag_name {
				return true
			}
		}
	}
	return false
}


