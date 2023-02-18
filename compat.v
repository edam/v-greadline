// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module gnu_readline

#flag darwin -I/usr/local/opt/readline/include
#flag darwin -L/usr/local/opt/readline/lib
#flag darwin -lreadline
#flag linux -lreadline

#include <readline/readline.h>

fn C.readline(prompt &char) &char
fn C.rl_parse_and_bind(line &char) int
fn C.rl_read_init_file(filename &char) int
fn C.rl_replace_line(text &char, clear_undo int)
fn C.rl_insert_text(text &char) int
fn C.rl_clear_history()

#include <readline/history.h>

pub struct C._hist_entry {
	line      &char
	timestamp &char
	data      voidptr
}

fn C.read_history(filename &char) int
fn C.write_history(filename &char) int
fn C.append_history(nelements int, filename &char) int
fn C.history_truncate_file(filename &char, nlines int) int
fn C.history_get(offset int) &C._hist_entry
fn C.remove_history(which int) &C._hist_entry
fn C.replace_history_entry(which int, line &char, data voidptr) &C._hist_entry
fn C.add_history(str &char)
