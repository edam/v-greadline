// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module greadline

import os

struct GlobalState {
mut:
	auto_add bool = true // auto-add enabled
	hf_limit int  = -1 // history file limit
	hf_name  string        // history file name
	comp_fn  ?CompletionFn // completion function
	comp_res []string      // completion results
}

@[unsafe]
fn global_state() &GlobalState {
	unsafe {
		mut static state := nil
		if state == nil {
			state = &GlobalState{}
		}
		return &GlobalState(state)
	}
}

fn check_error(ret int) ! {
	if ret != 0 {
		return error('failed')
	}
}

fn check_ptr(ret voidptr) ! {
	if ret == unsafe { nil } {
		return error('idx out of range')
	}
}

fn check_errno(errno_ int, must_exist bool) ! {
	if !must_exist && errno_ == 2 {
		return
	}
	if errno_ > 0 {
		return error('failed: ${os.posix_get_error_msg(errno_)}')
	}
}

fn apply_file_limit(length int) ! {
	state := unsafe { global_state() }
	ret := C.history_truncate_file(state.hf_name.str, length)
	check_errno(ret, false)!
}

fn completion_handler(word &char, next int) &char {
	mut state := unsafe { global_state() }
	if next == 0 {
		state.comp_res.clear()
		if comp_fn := state.comp_fn {
			state.comp_res << comp_fn(unsafe { cstring_to_vstring(word) })
			state.comp_res.reverse_in_place()
		}
	}
	if state.comp_res.len > 0 {
		res := state.comp_res.pop()
		ptr := unsafe { C.malloc(res.len + 1) } // use C malloc because...
		unsafe { vmemcpy(ptr, res.str, res.len + 1) } // include zero-terminator
		return ptr // ...GNU readline will free() memory
	} else {
		return C.NULL
	}
}

// type CompHandlerFn = fn (_ &char, _ int) &&char

fn enable_completion_handler(enable bool) {
	// TODO: assign to &&CompHandlerFn, not a &&char (this doesn't seem to work
	// at the moment--it complains that *cvarptr can't be assigned to...)
	// mut cvarptr := unsafe{ &&CompHandlerFn(&C.rl_completion_entry_function) }
	// unsafe { *cvarptr = &CompHandlerFn(&completion_handler) }
	mut cvarptr := unsafe { &&char(&C.rl_completion_entry_function) }
	unsafe {
		*cvarptr = if enable { &char(&completion_handler) } else { C.NULL }
	}
}

type ReadlineCommandFn = fn (int, int) int

fn wrap_bindable_fn(f CommandFn) ReadlineCommandFn {
	return fn [f] (count int, key int) int {
		return if f(count, 0) { 0 } else { 1 }
	}
}
