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

const (
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

// green - return a green string.
fn green(msg string) string {
	return "${color_green}${msg}${color_reset}"
}

// [design]
// functionalities
// - green -> create 1 green message (no \n); use it with println() for console output; color scheme reset automatically
// - green_forever -> set the color scheme and create a green message, but do not RESET the color scheme; continues to be green until reset
// - green_strong -> strong version of green
// - green_strong_forever -> strong version of green_forever
// - reset -> reset color scheme manually, useful when xxx_forever() has been called earlier
// - gallery -> displays a gallery of possible colors to the stdout; kind of reference for the developer to choose.