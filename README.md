greadline
============

A module for the [V programming language] which facilitates the use of the
[GNU Readline library] via a more simple interface.  (The interface is loosely
based on the Python GNU readline interface, although the functions in this
module are named more clearly.)

Version 0.2

Installation
------------

``` Shell
$ v install edam.greadline
```

Usage
=====

``` V
import greadline

fn main() {
	text := greadline.readline('Enter text> ') or { return }
	println("You typed: ${text}")
}
```

You can use `greadline.read_init_file(filename)` to initlaise the library.

History File
------------

To add history, simply load the file and that will set the filename used in
subsequent calls, such as writing history, which you will want to defer to
happen at program termination:

``` V
greadline.history_file_read(filename)!
defer {
    greadline.history_file_write() or {}
}
```

Note: it is not an error when `history_file_read()` is given a filename that
does not exist.  You should use `os.exists()` to discover that.

You can set a sensible limit on the size of the history file.  This will
immediately truncate the history file (if it exceeds the limit) and will affect
subsequent calls to `history_file_write()` and `history_file_append()`:

``` V
greadline.set_history_file_limit(1000)!
```

Completion
----------

TODO

Multiple Prompts
----------------

For differnt prompts, you may want different histories and completion rules.

TODO

Manipulating Line Buffer
------------------------

While readline is taking input, you can manipulate the process from another
thread.

``` V
old_pos := point()      // get current cursor position
set_point(5)            // set cursor position
insert_text("hi")       // insert text at cursor
set_point(old_pos)      // restore cursor position
delete_text(0, 3)       // delete the first 3 chars!
```

You can also modify/delete text by reading/write the input line buffer directly.

``` V
line := line_buffer()   // get the input line
ul := line.to_upper()
set_line_buffer(ul)     // set the new input line
```

Development
===========

Testing the module

``` shell
$ v test .
```

Licence
-------

Copyright (C) 2023 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Readline library]: https://tiswww.case.edu/php/chet/readline/rltop.html
