// Copyright (c) 2023 Tim Marston <tim@ed.am>.  All rights reserved.
// Use of this file is permitted under the terms of the GNU General Public
// Licence, version 3 or later, which can be found in the LICENCE file.

module greadline

import os

const (
	good_file = 'test-data/test.history'
	bad_file  = '27576b0ba552185ff6556e716b5ffaebf8fd4db67b362a9d433c991ce9b6e0f9'
	tmp_file  = 'temporary.history'
	dir_file  = 'test-data'
)

fn test_init() {
	assert history_length() == 0
}

fn test_errno() {
	mut ok := true

	// error for non-existent rc file
	read_init_file(bad_file) or { ok = false }
	assert !ok

	// no error for non-existent history
	history_file_read(bad_file) or { assert false }

	// error reading dir
	ok = true
	history_file_read(dir_file) or { ok = false }
	assert !ok
}

fn test_read_history() {
	history_file_read(good_file) or { assert false }
	assert history_length() == 3
	assert history_get(0) or { '' } == 'test line 1'
	assert history_get(-1) or { '' } == ''
	assert history_get(3) or { '' } == ''
	history_append('TESTLINE4')
	assert history_get(3) or { '' } == 'TESTLINE4'
}

fn test_memory_history() {
	mut ok := true

	history_clear()
	assert history_length() == 0
	history_append('test line 1')
	history_append('test line 2')
	assert history_length() == 2
	assert history_get(0)! == 'test line 1'
	assert history_get(1)! == 'test line 2'
	history_replace(0, 'test LINE 1')!
	assert history_get(0)! == 'test LINE 1'
	assert history_get(1)! == 'test line 2'
	history_replace(1, 'test LINE 2')!
	assert history_get(0)! == 'test LINE 1'
	assert history_get(1)! == 'test LINE 2'
	assert history_length() == 2
	history_remove(0)!
	assert history_length() == 1
	assert history_get(0)! == 'test LINE 2'
	assert history_get(1) or { '' } == ''
	ok = false
	history_remove(1) or { ok = true }
	assert ok
	history_remove(0)!
	assert history_length() == 0
	assert history_get(0) or { '' } == ''
	assert history_get(1) or { '' } == ''

	history_append('test line 3')
	assert history_length() == 1
	history_clear()
	assert history_length() == 0
}

fn check_hist_file(expected int, last string) ! {
	assert os.exists(tmp_file)
	lines := os.read_lines(tmp_file)!
	assert lines.len == expected
	assert lines.last() == last
}

fn test_write_history() {
	os.rm(tmp_file) or {}
	assert !os.exists(tmp_file)
	defer {
		os.rm(tmp_file) or { assert false }
	}
	history_clear()
	assert history_length() == 0
	history_file_read(tmp_file) or { assert false }
	assert history_file_limit() or { -999 } == -999

	history_append('test line 1')
	history_append('test line 2')
	history_append('test line 3')
	history_append('test line 4')
	history_file_write()!
	check_hist_file(4, 'test line 4')!

	set_history_file_limit(8)!
	assert history_file_limit() or { -999 } == 8
	check_hist_file(4, 'test line 4')!

	set_history_file_limit(2)!
	assert history_file_limit() or { -999 } == 2
	check_hist_file(2, 'test line 4')!
	history_file_write()!
	history_append('test line 5')
	check_hist_file(2, 'test line 4')!
	history_file_write()!
	check_hist_file(2, 'test line 5')!

	set_history_file_limit(4)!
	check_hist_file(2, 'test line 5')!
	history_append('test line 6')
	history_append('test line 7')
	history_file_write()!
	check_hist_file(4, 'test line 7')!

	clear_history_file_limit()
	check_hist_file(4, 'test line 7')!
	history_file_write()!
	check_hist_file(7, 'test line 7')!

	assert history_length() == 7
	history_remove(1)!
	assert history_length() == 6
	history_file_write()!
	check_hist_file(6, 'test line 7')!
	set_history_file_limit(4)!
	check_hist_file(4, 'test line 7')!
	history_remove(1)!
	check_hist_file(4, 'test line 7')!
	history_file_write()!
	assert history_length() == 5
	check_hist_file(4, 'test line 7')!

	clear_history_file_limit()
}

fn test_append_history() {
	os.rm(tmp_file) or {}
	assert !os.exists(tmp_file)
	defer {
		os.rm(tmp_file) or { assert false }
	}
	history_clear()
	assert history_length() == 0
	history_file_read(tmp_file) or { assert false }
	assert history_file_limit() or { -999 } == -999

	history_append('test line 1')
	history_append('test line 2')
	history_file_write()!
	check_hist_file(2, 'test line 2')!
	history_append('test line 3')
	history_file_append(1)!
	check_hist_file(3, 'test line 3')!
	history_file_append(1)!
	check_hist_file(3, 'test line 3')!
	history_file_append(20)!
	check_hist_file(3, 'test line 3')!

	set_history_file_limit(3)!
	check_hist_file(3, 'test line 3')!
	history_file_append(1)!
	check_hist_file(3, 'test line 3')!
	history_append('test line 4')
	history_file_append(10)!
	check_hist_file(3, 'test line 4')!

	clear_history_file_limit()
}

fn test_line_buffer() {
	assert length() == 0
	assert line_buffer() == ''
	set_line_buffer('0123456789')
	assert length() == 10
	assert line_buffer() == '0123456789'

	assert point() == 0
	// assert mark() or { -999 } == -999

	set_point(99)
	assert point() == 10
	set_point(-32)
	assert point() == 0
	set_point(5)
	assert point() == 5

	// set_mark(-66)
	// assert mark() or { -999 } == 0
	// set_mark(66)
	// assert mark() or { -999 } == 10
	// set_mark(8)
	// assert mark() or { -999 } == 8

	// clear_mark()
	// assert mark() or { -999 } == -999

	assert insert_text('abc') == 3
	assert length() == 13
	assert line_buffer() == '01234abc56789'
	assert delete_text(3, 6) == 3
	assert length() == 10
	assert line_buffer() == '012bc56789'
	assert delete_text(6, 3) == 3
	assert length() == 7
	assert line_buffer() == '0126789'
	assert delete_text(-99, 1) == 1
	assert length() == 6
	assert line_buffer() == '126789'
	assert delete_text(length(), 999) == 0
	assert length() == 6
	assert line_buffer() == '126789'
	assert delete_text(length() - 1, 999) == 1
	assert length() == 5
	assert line_buffer() == '12678'
}
