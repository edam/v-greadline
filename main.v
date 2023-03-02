// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module greadline

import math

// Binding keys

// Parse line as if it had been read from the inputrc file and perform any key
// bindings and variable assignments found.
pub fn parse_and_bind(line string) ! {
    // GNU readine presumes it can write to the string memory during parsing, so
    // we must realloc in writable memory.
    mem := unsafe{ memdup(line.str, line.len + 1) }
    defer { unsafe{ free(mem) } }
	ret := C.rl_parse_and_bind(mem)
	check_error(ret)!
}

// Read keybindings and variable assignments from filename.
pub fn read_init_file(filename string) ! {
	ret := C.rl_read_init_file(filename.str)
	check_errno(ret, true)!
}

type Key = int
type CommandFn = fn(int, Key) bool

// Add a custom, named, bindable function.  The function can be bound to a key
// with parse_and_bind(), e.g.: parse_and_bind('Control-x: my-foo-func').  See
// the GNU readline manual (search for "Key Bindings") for key names.
// https://tiswww.case.edu/php/chet/readline/readline.html#Readline-Init-File-Syntax
pub fn add_bindable_fn(name string, custom_fn CommandFn) {
    C.rl_add_funmap_entry(name.str, wrap_bindable_fn(custom_fn))
}

// Line buffer

// Emit prompt, then read and return user input.  Where EOF is encountered, none
// is returned.
pub fn readline(prompt string) ?string {
	ret := C.readline(prompt.str)
	if ret == C.NULL {
		return none
	}
	str := unsafe { ret.vstring() } // manage cstring (i.e., we should free() it)
	if str.len > 0 {
		state := unsafe { global_state() }
		if state.auto_add {
			history_append(str)
		}
	}
	return str
}

// Stop any ongoing readline() and return line buffer immediately.
pub fn readline_cancel() {
	C.rl_done = 1
}

// Returns the line gathered so far.
pub fn line_buffer() string {
	lb := &char(C.rl_line_buffer)
	unsafe {
		return if lb == nil { '' } else { cstring_to_vstring(lb) }
	}
}

// Replace the contents of the line buffer.  The point and mark are preserved,
// if possible.
pub fn set_line_buffer(line string) {
	C.rl_replace_line(line.str, 0)
}

// Insert text into the line at the current cursor position. Returns the number
// of characters inserted.
pub fn insert_text(text string) int {
	return C.rl_insert_text(text.str)
}

// Delete range of chars in the input buffer, from start pos to (but not
// including) end pos.  Returns the number of chars deleted.
pub fn delete_text(start int, end int) int {
	start_ := math.max(0, math.min(C.rl_end, start))
	end_ := math.max(0, math.min(C.rl_end, end))
	return C.rl_delete_text(start_, end_)
}

// Get line buffer length.
pub fn length() int {
	return C.rl_end
}

// Get point cursor position.
pub fn point() int {
	return C.rl_point
}

// Set point (cursor) position.
pub fn set_point(pos int) {
	C.rl_point = math.max(0, math.min(C.rl_end, pos))
}

// Get mark position.  If set, the text between point and mark is a selection.
pub fn mark() ?int {
    return if C.rl_mark_active_p() != 0 { C.rl_mark } else { none }
}

// Set mark position, and therefore set a text selection.
pub fn set_mark(pos int) {
    C.rl_mark = math.max(0, math.min( C.rl_end, pos ))
    C.rl_activate_mark()
}

// Unset mark, and therefore unselect any selected text.
pub fn clear_mark() {
    C.rl_deactivate_mark()
}

// History File Management

// Add the contents of filename to the history list, a line at a time.  The
// filename is saved to use with history_file_write() and history_file_append().
// the history file is not updated automatically and you may want to defer a
// call to history_file_write() at program termination.
pub fn history_file_read(filename string) ! {
	ret := C.read_history(filename.str)
	check_errno(ret, false)!
	mut state := unsafe { global_state() }
	state.hf_name = filename
}

// Write the current history to filename, overwriting filename if necessary.
pub fn history_file_write() ! {
	history_file_append(C.history_length)!
}

// Append the last nelements of the history list to filename.
pub fn history_file_append(nelements int) ! {
	state := unsafe { global_state() }
	if state.hf_name.len == 0 {
		return error('no history file')
	} else if state.hf_limit >= 0 {
		retain := math.max(0, state.hf_limit - C.history_length)
		append := math.min(C.history_length, state.hf_limit)
		apply_file_limit(retain)!
		ret := C.append_history(append, state.hf_name.str)
		check_errno(ret, true)!
	} else {
		ret := C.write_history(state.hf_name.str)
		check_errno(ret, true)!
	}
}

// Get the limit on the history file length imposed on write_history().
pub fn history_file_limit() ?int {
	state := unsafe { global_state() }
	return if state.hf_limit >= 0 { state.hf_limit } else { none }
}

// Set the length (in lines) of the history file and truncate immediately (as
// necessary).  This affects history_file_write() and history_file_append().
pub fn set_history_file_limit(length int) ! {
	length_ := math.max(0, length)
	mut state := unsafe { global_state() }
	if state.hf_limit == -1 || state.hf_limit > length_ {
		if state.hf_name.len > 0 {
			apply_file_limit(length_)!
		}
	}
	state.hf_limit = length
}

// Turn off limiting of the history file size.  This affects history_file_write()
// and history_file_append().
pub fn clear_history_file_limit() {
	mut state := unsafe { global_state() }
	state.hf_limit = -1
}

// In-memory History Management

// Clear the history list by deleting all of the entries.
pub fn history_clear() {
	C.rl_clear_history()
}

// Get the current history length.
pub fn history_length() int {
	return C.history_length
}

// Return the history entry at position idx, where 0 <= idx < history_length().
// Returns an error if the idx is invalid.
pub fn history_get(idx int) !string {
	entry := C.history_get(idx + 1) // api is 1-based here (but not later!)
	check_ptr(entry)!
	return unsafe { cstring_to_vstring(entry.line) }
}

// Remove history entry at position idx from the history.  Returns an error
// if the idx is invalid.
pub fn history_remove(idx int) ! {
	entry := C.remove_history(idx)
	check_ptr(entry)!
}

// Replace history entry at position idx in the history with the new
// entry.  Returns an error if the idx is invalid.
pub fn history_replace(idx int, line string) ! {
	entry := C.replace_history_entry(idx, line.str, C.NULL)
	check_ptr(entry)!
}

// Append a new entry to the history.
pub fn history_append(line string) {
	C.add_history(line.str)
}

// Turn on/off auto-adding of non-empty user input lines to the in-memory
// history.  Auto-add is enabled by default.
pub fn set_history_autoadd(enable bool) {
	mut state := unsafe { global_state() }
	state.auto_add = enable
}

// Completion

type CompletionFn = fn (word string) []string

// Set the completion function.  This will be called to complete the word at or
// before point, which is passed to it.  It returns a list of all possible
// completions.
pub fn set_completion_fn(comp_fn CompletionFn) {
	mut state := unsafe { global_state() }
	state.comp_fn = comp_fn
	enable_completion_handler(true)
}

// Set default completion.  Readline completes words at or before point as
// though they are filename by default.
pub fn set_completion_default() {
	enable_completion_handler(false)
}

// Turn off completion altogether.
pub fn set_completion_off() {
	mut state := unsafe { global_state() }
	state.comp_fn = unsafe { nil }
	enable_completion_handler(true)
}
