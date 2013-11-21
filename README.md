Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

I'm currently working out the architecture: How the formatting works in general, how formatting options are kept and passed, etc.
At the end of this phase, I should have a formatter with support for only a few language features and formatting options, but with that support being very generic and easily expandable.
When I'm comfortable with the architecture, all there's left to do is implementing more language features and formatting options.

Building
--------------------

1. Install the Ceylon IDE, following [these instructions](http://ceylon-lang.org/documentation/1.0/ide/install/)
2. Clone the repository locally
3. In Eclipse, go to File -> Import... -> Existing Projects into Workspace, then choose the location of the `ceylon.formatter` repository and import the `ceylon.formatter` project
4. Run `source_gen.ceylon.formatter.run()` (ignore the warning that the project has build errors, that’s exactly what this is going to fix)
5. Right-click the `test.ceylon.formatter` module and choose Run As -> Ceylon Test to test if everything works

Due to some quirks in the Ceylon IDE, you might have to clean the project a few times during this process.

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
