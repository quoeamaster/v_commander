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

pub type Stringbuffer = []byte

pub fn new_string_buffer(initial_size int) Stringbuffer {
	return Stringbuffer([]byte{cap: initial_size})
}

pub fn (mut b Stringbuffer) write_b(data byte) {
	b << data
}

// write implements the Writer interface
pub fn (mut b Stringbuffer) write(data []byte) ?int {
	if data.len == 0 {
		return 0
	}
	b << data
	return data.len
}

[inline]
pub fn (b &Stringbuffer) byte_at(n int) byte {
	return unsafe { (&[]byte(b))[n] }
}

// write appends the string `s` to the buffer
[inline]
pub fn (mut b Stringbuffer) write_string(s string) {
	if s.len == 0 {
		return
	}
	unsafe { b.push_many(s.str, s.len) }
}

// [BUG] ?? seems there is a conflict between the original Builder.str() with the compiler. 
// Probably something also has a fn named as "str".
// PS. the [trim] parameter is important, as it determines whether a "trim / reset" is taken on the buffer. 
pub fn (mut b Stringbuffer) to_string(trim bool) string {
	b << byte(0)
	bcopy := unsafe { &byte(memdup(b.data, b.len)) }
	s := unsafe { bcopy.vstring_with_len(b.len - 1) }
	// reset...
	if trim {
		b.trim(0)
	}
	return s
}


[unsafe]
pub fn (mut b Stringbuffer) free() {
	unsafe { free(b.data) }
}