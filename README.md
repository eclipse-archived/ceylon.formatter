Ceylon Formatter
================

The goal of this project is to provide a formatter for Ceylon source code that can be embedded in the Eclipse and IntelliJ IDE, as well as directly called from the command line.

Current status
--------------

I'm currently working out the architecture: How the formatting works in general, how formatting options are kept and passed, etc.
At the end of this phase, I should have a formatter with support for only a few language features and formatting options, but with that support being very generic and easily expandable.
When I'm comfortable with the architecture, all there's left to do is implementing more language features and formatting options.

Building and running
--------------------

### Environment

You'll need a *very* recent version of Ceylon and the compiler (unless 1.0.0 is already out when you're reading this).
For this, you need to build both your Ceylon and your Ceylon IDE from source.
I haven't tested these instructions, but I hope they should work, or at least get you on your way:

    mkdir ceylon && cd ceylon
    git clone https://github.com/ceylon/ceylon-dist.git
    cd ceylon-dist
    ant update-all publish-all
    cd ..
    git clone https://github.com/ceylon/ceylon-ide-eclipse.git
    mvn clean install -Dmaven.test.skip
    # now install it into your Eclipse from the update site ceylon/ceylon-ide-eclipse/site/target/site

You probably also need to do the following:

* Add the ANTLR runtime as dependency to the Ceylon typechecker, as outlined by Gavin King [here](https://github.com/ceylon/ceylon-ide-eclipse/issues/385#issuecomment-26142986)
* Update the `typechecker` binary of the IDE `defaultRepository` (located in `ceylon-ide-eclipse/plugins/com.redhat.ceylon.eclipse.ui/defaultRepository`) to a version built from source to include `VisitorAdaptor`
  (This step will be obsolete as soon as the binaries are updated again upstream, which will hopefully be soon)

### The formatter

Then compile and run the `source_gen.ceylon.formatter` module (in folder `source-gen`), which generates a few sources for the formatter;
then you can finally compile `ceylon.formatter`.
To check if everything went well, you can run the tests in `test.ceylon.formatter` (in folder `source-test`).

### Too complicated?

One of my goals ([issue #3](https://github.com/lucaswerkmeister/ceylon-formatter/issues/3)) is to automate the build process.
If these instructions were too much for you, poke that issue, say that I should make that a priority, and then watch and wait.

License
-------

The content of this repository is released under the ASL v2.0
as provided in the LICENSE file that accompanied this code.

By submitting a "pull request" or otherwise contributing to 
this repository, you agree to license your contribution under 
the license mentioned above.
