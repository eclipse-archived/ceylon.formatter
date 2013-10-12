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

The formatter is being developed inside a [ceylon-ide-eclipse](https://github.com/ceylon/ceylon-ide-eclipse) which is itself ran from source, with the following modifications made:

    * Add the ANTLR runtime as dependency to the Ceylon typechecker, as outlined by Gavin King [here](https://github.com/ceylon/ceylon-ide-eclipse/issues/385#issuecomment-26142986)
    * Update the `typechecker` binary of the IDE `defaultRepository` (located in `ceylon-ide-eclipse/plugins/com.redhat.ceylon.eclipse.ui/defaultRepository`) to a version built from source to include `VisitorAdaptor`
      (This step will be obsolete as soon as the binaries are updated again upstream, which will hopefully be soon)

It might very well be possible to compile and run the formatter using a different setup, but I'm happy with my current setup and don't want to risk breaking it :D If you succeed, contact me!

The `test-source` subdirectory contains Ceylon test cases, most notably `testSamples`, which tests sample files (located in `test-samples`) and compares the output to a given formatted version of the file.
You can look at these sample files to get an idea of what the formatter is currently capable of doing.

You can also directly run `run` from `source` with the path to a ceylon file as the first argument.
(The second argument can specify an output file, but I recommend strongly against this: The formatter isn't ready for such use yet.
If this argument is omitted, the output is just printed to `stdout`, which is safe.)

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.