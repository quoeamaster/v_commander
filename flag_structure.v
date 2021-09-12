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

// Flag - represents a CLI flag.
pub struct Flag {
pub mut:	
	// flag - e.g. --help (starts with 2 '--')
	flag string
	// short_flag - e.g. -h (starts with a single '-')
	short_flag string
	// flag_type - defines the value type of the flag.
	flag_type i8
	// usage - the message to explain how this flag should be configured (e.g. acceptable values)
	// possible syntax -> 
	//  "this flag accepts key=value settings, e.g. -E ocean_name=Arctic" OR 
	//  "this flag accepts a number, e.g. --age 22" OR 
	//  "this flag accepts an optioanl boolean value, omitted value equals to TRUE, e.g. --verbose OR --verbose true"
	usage string
	// required - indicate whether this Flag is required for its associated CLI.
	required bool

	// [deprecated] default_value - default value for this flag if configured.
	// [reason] struct could not support generic struct underneath... (bug or feature or limitation ???)
	// default_value T
}

// is_flag_valid - validates whether the flag is configured correctly.
pub fn (f Flag) is_flag_valid() ?bool {
	// rule 1. either flag or short_flag MUST be set
	if f.flag == "" && f.short_flag == "" {
		return error("[Flag][is_flag_valid] either 'flag' or 'short_flag' MUST be set.")
	}
	// rule 2. flag_type must be set
	// default value usually == 0, unless pointers ... then use isnil(variable) to test null or not.
	if f.flag_type == 0 {
		return error("[Flag][is_flag_valid] 'flag_type' MUST be set.")
	}
	return true
} 



// [design]
// - Flag's value validation is done through the CLI's [run] logic; and not by the Flag itself, 
//   Flag is just a container to describe what a Flag would behave. 
//   e.g. value range within 1 ~ 5 would be guarded by the CLI's [run] logic.
// - Flag was designed to support generics... the [default_value] was once supported, 
//   however due to V's handling on a parent Struct to embed a Generic-Struct, this feature is deprecated or should say removed...
// - Bool Flag defaults to FALSE, so if a bool flag is provided it should be set to TRUE, which means it is an optional flag 
//   (doesn't need to provide a bool value -> e.g. "--trace" instead of "--trace true")

// pub fn (f Flag<T>) is_flag_valid() ?bool {}