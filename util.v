// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module greadline

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
	msg := match errno_ {
		1 { 'Not super-user' }
		5 { 'I/O error' }
		6 { 'No such device or address' }
		12 { 'Not enough memory' }
		13 { 'Permission denied' }
		16 { 'Mount device busy' }
		17 { 'File exists' }
		21 { 'Is a directory' }
		23 { 'Too many open files in system' }
		24 { 'Too many open files' }
		28 { 'No space left on device' }
		30 { 'Read only file system' }
		89 { 'No more files' }
		91 { 'File or path name too long' }
		137 { 'Filename exists with different case' }
		else { 'errno_ ${errno_}' }
	}
	if errno_ > 0 {
		return error('failed: ${msg}')
	}
}

fn apply_file_limit(length int) ! {
	state := unsafe { global_state() }
	ret := C.history_truncate_file(state.hfname.str, length)
	check_errno(ret, false)!
}
