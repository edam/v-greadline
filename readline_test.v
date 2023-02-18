module gnu_readline

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
	read_init_file(gnu_readline.bad_file) or { ok = false }
	assert !ok

	// no error for non-existent history
	history_file_read(gnu_readline.bad_file) or { assert false }

	// error reading dir
	ok = true
	history_file_read(gnu_readline.dir_file) or { ok = false }
	assert !ok
}

fn test_read_history() {
	history_file_read(gnu_readline.good_file) or { assert false }
	assert history_length() == 3
	assert history_get(1) or { '' } == 'test line 1'
	assert history_get(0) or { '' } == ''
	assert history_get(4) or { '' } == ''
	history_append('TESTLINE4')
	assert history_get(4) or { '' } == 'TESTLINE4'
	history_clear()
	assert history_length() == 0
}

fn check_hist_file(expected int, last string) ! {
	assert os.exists(gnu_readline.tmp_file)
	lines := os.read_lines(gnu_readline.tmp_file)!
	assert lines.len == expected
	assert lines.last() == last
}

fn test_write_history() {
	os.rm(gnu_readline.tmp_file) or {}
	assert !os.exists(gnu_readline.tmp_file)
	defer {
		os.rm(gnu_readline.tmp_file) or { assert false }
	}
	history_file_read(gnu_readline.tmp_file) or { assert false }
	history_append('test line 1')
	history_append('test line 2')
	history_append('test line 3')
	history_append('test line 4')
	history_file_write()!
	check_hist_file(4, 'test line 4')!

	assert history_file_limit() or { -999 } == -999
	set_history_file_limit(2)!
	check_hist_file(2, 'test line 4')!
	history_file_write()!

	set_history_file_limit(4)!
	history_append('test line 5')
	history_append('test line 6')
	check_hist_file(2, 'test line 4')!
	history_file_write()!
	check_hist_file(4, 'test line 6')!

	clear_history_file_limit()
	history_file_write()!
	check_hist_file(6, 'test line 6')!
}
