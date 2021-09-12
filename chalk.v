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

// [design]
// functionalities
// - green -> create 1 green message (no \n); use it with println() for console output; color scheme reset automatically
// - green_forever -> set the color scheme and create a green message, but do not RESET the color scheme; continues to be green until reset
// - reset -> reset color scheme manually, useful when xxx_forever() has been called earlier
// - gallery -> displays a gallery of possible colors to the stdout; kind of reference for the developer to choose.

module vcommander

pub const (
	// color_reset - the default / resetted color for the console output.
	color_reset = "\033[0m"

	// color_red - red color
	color_red 				= "\033[31m"
	color_bold_red 		= "\033[1;31m"
	color_hi_red 			= "\033[0;91m"
	color_bold_hi_red 	= "\033[1;91m"

	// color_green - green color
	color_green 			= "\033[32m"
	color_bold_green 		= "\033[1;32m"
	color_hi_green 		= "\033[0;92m"
	color_bold_hi_green 	= "\033[1;92m"	

	// color_yellow - yellow color
	color_yellow				= "\033[33m"
	color_bold_yellow			= "\033[1;33m"
	color_hi_yellow 			= "\033[0;93m"
	color_bold_hi_yellow 	= "\033[1;93m"

	// color_blue - blue color
	color_blue				= "\033[34m"
	color_bold_blue		= "\033[1;34m"
	color_hi_blue			= "\033[0;94m"
	color_bold_hi_blue	= "\033[1;94m"

	// color_purple - purple color
	color_purple			= "\033[35m"
	color_bold_purple		= "\033[1;35m"
	color_hi_purple		= "\033[0;95m"
	color_bold_hi_purple	= "\033[1;95m"

	// color_cyan - cyan color
	color_cyan				= "\033[36m"
	color_bold_cyan		= "\033[1;36m"
	color_hi_cyan			= "\033[0;96m"
	color_bold_hi_cyan	= "\033[1;96m"

	// color_white - white color
	color_white				= "\033[37m"
	color_bold_white		= "\033[1;37m"
	color_hi_white			= "\033[0;97m"
	color_bold_hi_white	= "\033[1;97m"
)

// msg_in_color - create a message in a specific color, the [is_forever] parameter decides whether a color reset should be set.
fn msg_in_color(msg string, color string, is_forever bool) string {
	if is_forever {
		return "${color}${msg}"
	}
	return "${color}${msg}${color_reset}"
}

// colored - a way to provide a chosen [color] for your [msg]. Please check the color constants.
pub fn colored(msg string, color string, is_forever bool) string {
	return msg_in_color(msg, color, is_forever)
}

// reset_color - return a message in the reset / default color.
pub fn reset_color(msg string) string {
	return msg_in_color(msg, color_reset, false)
}

// green - return a green string.
pub fn green(msg string) string {
	return msg_in_color(msg, color_green, false)
}
// green_forever - return a green string.
pub fn green_forever(msg string) string {
	return msg_in_color(msg, color_green, true)
}

pub fn red(msg string) string {
	return msg_in_color(msg, color_red, false)
}
pub fn red_forever(msg string) string {
	return msg_in_color(msg, color_red, true)
}

pub fn yellow(msg string) string {
	return msg_in_color(msg, color_yellow, false)
}
pub fn yellow_forever(msg string) string {
	return msg_in_color(msg, color_yellow, true)
}

pub fn blue(msg string) string {
	return msg_in_color(msg, color_blue, false)
}
pub fn blue_forever(msg string) string {
	return msg_in_color(msg, color_blue, true)
}

pub fn purple(msg string) string {
	return msg_in_color(msg, color_purple, false)
}
pub fn purple_forever(msg string) string {
	return msg_in_color(msg, color_purple, true)
}

pub fn cyan(msg string) string {
	return msg_in_color(msg, color_cyan, false)
}
pub fn cyan_forever(msg string) string {
	return msg_in_color(msg, color_cyan, true)
}

pub fn white(msg string) string {
	return msg_in_color(msg, color_white, false)
}
pub fn white_forever(msg string) string {
	return msg_in_color(msg, color_white, true)
}

// chalk_gallery - display a demo on how each chalk looks like.
pub fn chalk_gallery() string {
	mut s := new_string_buffer(256)
	//s.write_string("[green]\n")
	s.write_string("${green('green'):-17} (normal) ${colored('green', color_hi_green, false):-17} (high color) ${colored('green', color_bold_green, false):-17} (bold) ${colored('green', color_bold_hi_green, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${red('red'):-17} (normal) ${colored('red', color_hi_red, false):-17} (high color) ${colored('red', color_bold_red, false):-17} (bold) ${colored('red', color_bold_hi_red, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${yellow('yellow'):-17} (normal) ${colored('yellow', color_hi_yellow, false):-17} (high color) ${colored('yellow', color_bold_yellow, false):-17} (bold) ${colored('yellow', color_bold_hi_yellow, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${blue('blue'):-17} (normal) ${colored('blue', color_hi_blue, false):-17} (high color) ${colored('blue', color_bold_blue, false):-17} (bold) ${colored('blue', color_bold_hi_blue, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${purple('purple'):-17} (normal) ${colored('purple', color_hi_purple, false):-17} (high color) ${colored('purple', color_bold_purple, false):-17} (bold) ${colored('purple', color_bold_hi_purple, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${cyan('cyan'):-17} (normal) ${colored('cyan', color_hi_cyan, false):-17} (high color) ${colored('cyan', color_bold_cyan, false):-17} (bold) ${colored('cyan', color_bold_hi_cyan, false):-17} (bold and higher)")

	s.write_string("\n")
	s.write_string("${white('white'):-17} (normal) ${colored('white', color_hi_white, false):-17} (high color) ${colored('white', color_bold_white, false):-17} (bold) ${colored('white', color_bold_hi_white, false):-17} (bold and higher)\n")

	return s.to_string(false)
}

