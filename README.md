Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

I'm currently working out the architecture: How the formatting works in general, how formatting options are kept and passed, etc.
At the end of this phase, I should have a formatter with support for only a few language features and formatting options, but with that support being very generic and easily expandable.
When I'm comfortable with the architecture, all there's left to do is implementing more language features and formatting options.

Running
-------

The `test` subdirectory contains JUnit test cases, most notably `TestSamples`, which tests sample files and compares the output to a given formatted version of the file.
You can look at these sample files to get an idea of what the formatter is currently capable of doing.

You can also directly run `Main.main` from `src` with the path to a ceylon file as the first argument.
(The second argument can specify an output file, but I recommend strongly against this: The formatter isn't ready for such use yet.
If this argument is omitted, the output is just printed to `stdout`, which is safe.)

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.