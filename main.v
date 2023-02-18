module gnu_readline

// This V module is a shim, wrapping GNU Readline.  Please see the GNU project
// documentation for readline for more information about the API:
// https://tiswww.case.edu/php/chet/readline/readline.html
//
import math

// Binding keys

// Parse line as if it had been read from the inputrc file and perform any key
// bindings and variable assignments found.
pub fn parse_and_bind(line string) ! {
	ret := C.rl_parse_and_bind(line.str)
	check_error(ret)!
}

// Read keybindings and variable assignments from filename.
pub fn read_init_file(filename string) ! {
	ret := C.rl_read_init_file(filename.str)
	check_errno(ret, true)!
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
		if state.autoadd {
			history_append(str)
		}
	}
	return str
}

// Returns the line gathered so far.
pub fn line_buffer() string {
	return unsafe { cstring_to_vstring(&char(C.rl_line_buffer)) }
}

// Replace the contents of the line buffer. The point and mark are preserved, if
// possible.
pub fn set_line_buffer(line string) {
	C.rl_replace_line(line.str, 0)
}

// Insert text into the line at the current cursor position. Returns the number
// of characters inserted.
pub fn insert_text(text string) int {
	return C.rl_insert_text(text.str)
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
	state.hfname = filename
}

// Write the current history to filename, overwriting filename if necessary.
pub fn history_file_write() ! {
	history_file_append(C.history_length)!
}

// Append the last nelements of the history list to filename.
pub fn history_file_append(nelements int) ! {
	state := unsafe { global_state() }
	if state.hfname.len == 0 {
		return error('no history file')
	} else if state.hflimit >= 0 {
		retain := math.max(0, state.hflimit - C.history_length)
		append := math.min(C.history_length, state.hflimit)
		apply_file_limit(retain)!
		ret := C.append_history(append, state.hfname.str)
		check_errno(ret, true)!
	} else {
		ret := C.write_history(state.hfname.str)
		check_errno(ret, true)!
	}
}

// Get the limit on the history file length imposed on write_history().
pub fn history_file_limit() ?int {
	state := unsafe { global_state() }
	return if state.hflimit >= 0 { state.hflimit } else { none }
}

// Set the length (in lines) of the history file and truncate immediately (as
// necessary).  This affects history_file_write() and history_file_append().
pub fn set_history_file_limit(length int) ! {
	length_ := math.max(0, length)
	mut state := unsafe { global_state() }
	if state.hflimit == -1 || state.hflimit > length_ {
		if state.hfname.len > 0 {
			apply_file_limit(length_)!
		}
	}
	state.hflimit = length
}

// Turn off limiting of the history file size.  This affects history_file_write()
// and history_file_append().
pub fn clear_history_file_limit() {
	mut state := unsafe { global_state() }
	state.hflimit = -1
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

// Return the history entry at position idx, where 0 < idx < history_length().
// Returns an error if the idx is invalid.
pub fn history_get(idx int) !string {
	entry := C.history_get(idx)
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
	state.autoadd = enable
}
