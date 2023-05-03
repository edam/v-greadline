greadline
=========

A module for the [V programming language] which facilitates the use of the
[GNU Readline library] via a more simple interface.  (The interface is loosely
based on the Python GNU readline interface, although the functions in this
module are named more clearly.)

Version 0.4

Installation
------------

``` Shell
$ v install edam.greadline
```

Usage
=====

``` V
import edam.greadline

fn main() {
	text := greadline.readline('Enter text> ') or { return }
	println("You typed: ${text}")
}
```

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

Initialisation
--------------

GNU readline will initialise with the user's (or system) readline init file
anyway.  But in addition you can use `greadline.read_init_file(filename)` to
read your own readline init file.

Alternatively, use `greadline.parse_and_bind(line)` to pass custom init file
lines to the library, one at a time.

Completion
----------

"Tab completion" can be controlled by providing a completion function.  The
completion function is passed the word at (or before) the cursor and must
returns all possible completions.

``` V
greadline.set_completion_fn(fn(word string) []string {
	return commands.filter(it.starts_with(word))
})
```

Completion can also be set back to the default (i.e., filenames) or turned off
completely.

``` V
greadline_set_completion_default()
greadline.set_completion_off()
```

Multiple Prompts
----------------

For different prompts, you may want different histories and completion rules.

TODO

Manipulating Line Buffer
------------------------

In addition to the builtin functions, you can add your own named functions to
readline and set key bindings for them, so that the user can trigger them while
entering text.

``` V
greadline.add_bindable_fn('star-first-chars', star_first_n_chars)
greadline.parse_and_bind('Control-g: star-first-chars')!
```

In your bindable function, you can then modify the line input buffer in various
ways.

``` V
pos := greadline.point()              // get current cursor position
greadline.set_point(5)                // set cursor position
greadline.insert_text("hi")           // insert 2 chars at the cursor
greadline.delete_text(5, 7)           // delete 2 chars at buffer offset 5
length := greadline.length()          // get input text length
mark := greadline.mark() or { -1 }    // get mark (selection offset) if set
greadline.set_mark(0)                 // set mark (selection) to offset 0
greadline.clear_mark()                // clear mark (unselect)
```

Or you can modify the whole input line buffer in one go and readine will try to
preserve point (the cursor position).  Here is the function we added above...

``` V
fn star_first_n_chars(count int, _ greadline.Key) bool {
	line := greadline.line_buffer()   // get the input line
	count_ := math.min(math.max(count, 0), line.len)
	line_ := '*'.repeat(count_) + line[count_..line.len]
	greadline.set_line_buffer(line_)  // set the new input line
	return true // no error
}
```

Notes on bindable functions:
* `count` is a an argument that the user can pass to the function while editing
  the line (like in Emacs) and it defaults to 1.  It is typically used as a
  "repeat count".
* The second argument (type `Key`) should not be used. (It will be added in the
  future, but the definition of `Key` will change.)
* Returns false on error.

Development
===========

Testing the module

``` shell
$ v test .
```

Changes
-------

0.1 Initial verison
0.2 Support more of API, bug fixes, API consistency, more tests
0.3 Added completion and custom bindable functions, bug fixes
0.4 Fixed file name

Licence
-------

Copyright (C) 2023 Tim Marston <tim@ed.am>

[GNU Lesser General Public Licence (version 3 or later)](../master/LICENCE)



[V programming language]: http://vlang.io
[GNU Readline library]: https://tiswww.case.edu/php/chet/readline/rltop.html
