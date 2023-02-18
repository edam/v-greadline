gnu_readline
============

A module for the [V programming language] which facilitates the use of the
[GNU Readline library] via a more simple interface.  (The interface is loosely
based on the Python GNU readline interface, although the functions in this
module are named more clearly.)

Version 0.1

Installation
------------

``` Shell
$ v install edam.gnu_readline
```

Usage
=====

``` V
import gnu_readline

fn main() {
	text := gnu_readline.readline('Enter text> ')
	println("You typed: ${text}")
}
```

You can use `gnu_readline.read_init_file(filename)` to initlaise the library.

History file
------------

To add history, simply load the file and it will set the filename for subsequent
calls:

``` V
    gnu_readline.history_file_read(history_filename)!
    defer {
         gnu_readline.history_file_write() or {}
    }
```

Defer writing of the history file for program termination as well.

Note: it is not an error for `history_file_read()` to be given a filename that
does not exist.  You should use `os.exists()` to discover that.

You may also want to limit the size of the history file.  Introducing a limit
immediately truncates the history file and affects subsequent calls to
`history_file_write()` and `history_file_append()`.

``` V
    gnu_readline.set_history_file_limit(1000)
```

Completion
----------

TODO

Multiple Prompts
----------------

For differnt prompts, you may want different histories and completion rules.

TODO


Licence
-------

Copyright (C) 2023 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Readline library]: https://tiswww.case.edu/php/chet/readline/rltop.html
