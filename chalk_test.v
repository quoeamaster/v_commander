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

// test_colors_1 - test on how ternminal colors could be modified.
fn test_colors_1() {
	println("\n### chalk_test.test_colors_1 ###\n")
	// [ref] https://gist.github.com/JBlond/2fea43a3049b38287e5e9cefc87b2124

	// red
	println("\033[31m - Red color~")
	println("still red... until... reseted...")
	// brighter red
	println("\033[1;31m - Red color~")
	// reset 
	println("\033[0m - back to default color")
	
	// green
	println("\033[32m - Greenie")
	// green - hi intensity
	println("\033[0m \033[0;92m - Green~")
	// green - brighter
	println("\033[1;32m - Greenie")
	println("\033[0m \033[1;92m - Green~")


	// yellow
	println("\033[0m \033[33m - Yellowish")
	// yellow - brighter
	println("\033[1;33m - Yellowish")

	// blue
	println("\033[0m \033[34m - Blues")
	// blue - brighter
	println("\033[1;34m - Blues")

	// purple
	println("\033[0m \033[35m - Purple / Magenta")
	// purple - brighter
	println("\033[1;35m - Purple / Magenta")

	// cyan
	println("\033[0m \033[36m - Cyan-ide")
	// cyan - brighter
	println("\033[1;36m - Cyan-ide")

	// white
	println("\033[0m\033[37m - Snow WHITE")
	// white - brighter
	println("\033[1;37m - Snow WHITE")

	// reset
	println("\033[0m - back to default")
}

fn test_chalk_green() {
	println("\n### chalk_test.test_chalk_green ###\n")

	println("this is message in green -> ${green('love to see you greenie~')}")
	println(green("another way to create a GREEN message~"))
	println("should be reset to default color afterwards....")

	println("\nstarted to green-forever contents")
	println(green_forever("${'Samson':-10}: Morning Peter~"))
	println("${'Peter':-10}: Hello Mr Samson, it is a GREEN day~")
	println("${'Samson':-10}: Yeah, and I will reset the color right away~")
	println(reset_color("${'Samson':-10}: see~ it worked"))

	println("\ntest on hi-green and bold-green and hi-bold-green")
	println(green("this is normal green"))
	println(colored("this is hi-green", color_hi_green, false))
	println(colored("this is bold-green", color_bold_green, false))
	println(colored("this is hi-bold-green", color_bold_hi_green, false))
	/*
	println("pointer of fn green -> ${green:p}")
	println("pointer of fn green -> ${green:p} again")
	*/
}

fn test_chalk_gallery() {
	println("\n### chalk_test.test_chalk_gallery ###\n")
	println(chalk_gallery())
}

