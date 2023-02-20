// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module greadline

import os

struct GlobalState {
mut:
	autoadd bool = true // auto-add enabled
	hflimit int  = -1 // history file limit
	hfname  string
}

[unsafe]
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
	ret := C.history_truncate_file(state.hfname.str, length)
	check_errno(ret, false)!
}
